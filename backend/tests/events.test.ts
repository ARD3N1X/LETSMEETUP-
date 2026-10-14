import { beforeEach, describe, expect, it } from 'vitest';
import { api, auth, createGroup, createUser, eventPayload, joinGroup, resetDb } from './helpers.js';

beforeEach(resetDb);

async function setup() {
  const owner = await createUser('Owner');
  const member = await createUser('Member');
  const stranger = await createUser('Stranger');
  const group = await createGroup(owner);
  await joinGroup(member, group.inviteCode);
  return { owner, member, stranger, group };
}

describe('events', () => {
  it('keeps private events private', async () => {
    const { owner, stranger } = await setup();
    const event = eventPayload();
    await api().post('/events').set(auth(owner)).send(event).expect(201);
    await api().get(`/events/${event.id}`).set(auth(owner)).expect(200);
    await api().get(`/events/${event.id}`).set(auth(stranger)).expect(404);
  });

  it('does not allow creating events in a group you are not a member of', async () => {
    const { stranger, group } = await setup();
    await api().post('/events').set(auth(stranger)).send(eventPayload({ groupId: group.id })).expect(404);
  });

  it('lets members see but not edit other members events; admins can edit', async () => {
    const { owner, member, group } = await setup();
    const event = eventPayload({ groupId: group.id });
    await api().post('/events').set(auth(member)).send(event).expect(201);

    await api().get(`/events/${event.id}`).set(auth(owner)).expect(200);
    const other = eventPayload({ groupId: group.id });
    await api().post('/events').set(auth(owner)).send(other).expect(201);
    await api().patch(`/events/${other.id}`).set(auth(member)).send({ title: 'X' }).expect(403);
    await api().delete(`/events/${other.id}`).set(auth(member)).expect(403);

    // Admin może edytować cudze wydarzenie w grupie.
    await api().patch(`/events/${event.id}`).set(auth(owner)).send({ title: 'Poprawione' }).expect(200);
  });

  it('applies partial updates without losing concurrent changes', async () => {
    const { owner, group } = await setup();
    const event = eventPayload({ groupId: group.id });
    await api().post('/events').set(auth(owner)).send(event).expect(201);
    await api().patch(`/events/${event.id}`).set(auth(owner)).send({ title: 'X' }).expect(200);
    const res = await api().patch(`/events/${event.id}`).set(auth(owner)).send({ color: '#FDFD96' }).expect(200);
    expect(res.body).toMatchObject({ title: 'X', color: '#FDFD96', version: 3, allDay: false });
  });

  it('validates the schedule', async () => {
    const { owner } = await setup();
    const res = await api()
      .post('/events')
      .set(auth(owner))
      .send(eventPayload({ startAt: '2026-08-14T10:00:00Z', endAt: '2026-08-14T09:00:00Z' }))
      .expect(400);
    expect(res.body.error.code).toBe('END_BEFORE_START');
    await api().post('/events').set(auth(owner)).send(eventPayload({ title: '   ' })).expect(400);
  });

  it('stores all-day events as calendar dates', async () => {
    const { owner } = await setup();
    const res = await api()
      .post('/events')
      .set(auth(owner))
      .send(eventPayload({ allDay: true, startAt: '2026-08-14T13:45:00Z', endAt: '2026-08-15T08:00:00Z' }))
      .expect(201);
    expect(res.body.startAt).toBe('2026-08-14T00:00:00.000Z');
    expect(res.body.endAt).toBe('2026-08-15T00:00:00.000Z');
  });

  it('is idempotent for retried creates', async () => {
    const { owner, member } = await setup();
    const event = eventPayload();
    await api().post('/events').set(auth(owner)).send(event).expect(201);
    await api().post('/events').set(auth(owner)).send(event).expect(201);
    await api().post('/events').set(auth(member)).send(event).expect(409);
  });

  it('creates and undoes painted copies in batches', async () => {
    const { owner, group } = await setup();
    const copies = ['2026-08-15', '2026-08-16', '2026-08-17'].map((d) =>
      eventPayload({ groupId: group.id, startAt: `${d}T10:00:00Z`, endAt: `${d}T11:00:00Z` }),
    );
    const created = await api().post('/events/batch').set(auth(owner)).send({ events: copies }).expect(201);
    expect(created.body).toHaveLength(3);

    const undo = await api()
      .post('/events/batch-delete')
      .set(auth(owner))
      .send({ ids: copies.map((c) => c.id) })
      .expect(200);
    expect(undo.body.deleted).toHaveLength(3);
    await api().get(`/events/${copies[0]!.id}`).set(auth(owner)).expect(404);
  });

  it('manages exceptions of recurring events', async () => {
    const { owner } = await setup();
    const event = eventPayload({ recurrence: { freq: 'weekly', interval: 1, byWeekDay: [5] } });
    await api().post('/events').set(auth(owner)).send(event).expect(201);

    const cancelled = await api()
      .put(`/events/${event.id}/exceptions/2026-08-21`)
      .set(auth(owner))
      .send({ cancelled: true })
      .expect(200);
    expect(cancelled.body.exceptions).toEqual([expect.objectContaining({ date: '2026-08-21', cancelled: true })]);

    const overridden = await api()
      .put(`/events/${event.id}/exceptions/2026-08-21`)
      .set(auth(owner))
      .send({ title: 'Przesunięte' })
      .expect(200);
    expect(overridden.body.exceptions[0]).toMatchObject({ cancelled: false, title: 'Przesunięte' });

    const restored = await api().delete(`/events/${event.id}/exceptions/2026-08-21`).set(auth(owner)).expect(200);
    expect(restored.body.exceptions).toEqual([]);

    const single = eventPayload();
    await api().post('/events').set(auth(owner)).send(single).expect(201);
    await api().put(`/events/${single.id}/exceptions/2026-08-14`).set(auth(owner)).send({ cancelled: true }).expect(400);
  });

  it('rejects contradictory recurrence rules', async () => {
    const { owner } = await setup();
    await api()
      .post('/events')
      .set(auth(owner))
      .send(eventPayload({ recurrence: { freq: 'daily', interval: 1, count: 3, until: '2026-09-01' } }))
      .expect(400);
    const res = await api()
      .post('/events')
      .set(auth(owner))
      .send(eventPayload({ recurrence: { freq: 'daily', interval: 1, until: '2026-01-01' } }))
      .expect(400);
    expect(res.body.error.code).toBe('UNTIL_BEFORE_START');
  });
});
