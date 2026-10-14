import { createServer, type Server } from 'node:http';
import type { AddressInfo } from 'node:net';
import { io as connect, type Socket } from 'socket.io-client';
import { afterAll, beforeAll, beforeEach, describe, expect, it } from 'vitest';
import { prisma } from '../src/db.js';
import { initRealtime } from '../src/realtime/io.js';
import { api, app, auth, createGroup, createUser, eventPayload, joinGroup, resetDb } from './helpers.js';

beforeEach(resetDb);

const sync = async (user: Parameters<typeof auth>[0], since?: string) =>
  (await api().get('/sync').query(since ? { since } : {}).set(auth(user)).expect(200)).body;

describe('sync', () => {
  it('returns a full snapshot without a cursor', async () => {
    const owner = await createUser();
    const group = await createGroup(owner);
    await api().post('/events').set(auth(owner)).send(eventPayload()).expect(201);
    await api().post('/events').set(auth(owner)).send(eventPayload({ groupId: group.id })).expect(201);
    const body = await sync(owner);
    expect(body.full).toBe(true);
    expect(body.groups).toHaveLength(1);
    expect(body.events).toHaveLength(2);
  });

  it('delivers deletions to clients that were offline', async () => {
    const owner = await createUser();
    const member = await createUser();
    const group = await createGroup(owner);
    await joinGroup(member, group.inviteCode);
    const event = eventPayload({ groupId: group.id });
    await api().post('/events').set(auth(owner)).send(event).expect(201);

    const first = await sync(member);
    expect(first.events.map((e: { id: string }) => e.id)).toContain(event.id);

    await api().delete(`/events/${event.id}`).set(auth(owner)).expect(200);
    const delta = await sync(member, first.serverTime);
    expect(delta.full).toBe(false);
    expect(delta.deletedEventIds).toContain(event.id);
  });

  it('includes older events of a newly joined group', async () => {
    const owner = await createUser();
    const member = await createUser();
    const group = await createGroup(owner);
    const event = eventPayload({ groupId: group.id });
    await api().post('/events').set(auth(owner)).send(event).expect(201);

    // Wydarzenie jest "stare" względem kursora klienta.
    await prisma.event.update({ where: { id: event.id }, data: { updatedAt: new Date(Date.now() - 3_600_000) } });
    const since = new Date(Date.now() - 60_000).toISOString();
    const before = await sync(member, since);
    expect(before.events).toHaveLength(0);

    await joinGroup(member, group.inviteCode);
    const delta = await sync(member, since);
    expect(delta.events.map((e: { id: string }) => e.id)).toContain(event.id);
  });

  it('removes an event from the old group when it is moved', async () => {
    const owner = await createUser();
    const member = await createUser();
    const group = await createGroup(owner);
    await joinGroup(member, group.inviteCode);
    const event = eventPayload({ groupId: group.id });
    await api().post('/events').set(auth(owner)).send(event).expect(201);
    const first = await sync(member);

    await api().patch(`/events/${event.id}`).set(auth(owner)).send({ groupId: null }).expect(200);
    const delta = await sync(member, first.serverTime);
    expect(delta.deletedEventIds).toContain(event.id);
    await api().get(`/events/${event.id}`).set(auth(member)).expect(404);

    const ownerDelta = await sync(owner, first.serverTime);
    expect(ownerDelta.deletedEventIds).not.toContain(event.id);
    expect(ownerDelta.events.map((e: { id: string }) => e.id)).toContain(event.id);
  });
});

describe('realtime', () => {
  let server: Server;
  let url: string;
  const sockets: Socket[] = [];

  beforeAll(async () => {
    server = createServer(app);
    initRealtime(server);
    await new Promise<void>((resolve) => server.listen(0, resolve));
    url = `http://localhost:${(server.address() as AddressInfo).port}`;
  });

  afterAll(async () => {
    sockets.forEach((s) => s.close());
    await new Promise((resolve) => server.close(resolve));
  });

  const open = (token: string) =>
    new Promise<Socket>((resolve, reject) => {
      const socket = connect(url, { auth: { token }, transports: ['websocket'] });
      sockets.push(socket);
      socket.on('ready', () => resolve(socket));
      socket.on('connect_error', reject);
    });

  const next = <T>(socket: Socket, name: string) => new Promise<T>((resolve) => socket.once(name, resolve));

  it('rejects connections without a valid token', async () => {
    await expect(open('invalid')).rejects.toThrow('INVALID_TOKEN');
  });

  it('pushes group changes to members, including groups joined after connecting', async () => {
    const owner = await createUser();
    const member = await createUser();
    const group = await createGroup(owner);
    const memberSocket = await open(member.token);

    // Dołączenie po nawiązaniu połączenia — serwer sam dopina pokój grupy.
    const changed = next(memberSocket, 'groups:changed');
    await joinGroup(member, group.inviteCode);
    await changed;

    const upsert = next<{ event: { id: string; title: string }; actorId: string }>(memberSocket, 'event:upsert');
    const event = eventPayload({ groupId: group.id, title: 'Kickoff' });
    await api().post('/events').set(auth(owner)).send(event).expect(201);
    const payload = await upsert;
    expect(payload.event).toMatchObject({ id: event.id, title: 'Kickoff' });
    expect(payload.actorId).toBe(owner.id);

    const removed = next<{ groupId: string }>(memberSocket, 'group:removed');
    await api().delete(`/groups/${group.id}/members/${member.id}`).set(auth(owner)).expect(200);
    expect((await removed).groupId).toBe(group.id);
  });
});
