import { randomUUID } from 'node:crypto';
import request from 'supertest';
import { createApp } from '../src/app.js';
import { prisma } from '../src/db.js';
import { sentMails } from '../src/lib/mailer.js';

export const app = createApp();
export const api = () => request(app);

export async function resetDb() {
  await prisma.$executeRawUnsafe(
    'TRUNCATE event_tombstones, event_exceptions, events, group_members, groups, device_tokens, email_codes, refresh_tokens, users CASCADE',
  );
  sentMails.length = 0;
}

export function lastCode(email: string) {
  const mail = [...sentMails].reverse().find((m) => m.to === email);
  const code = mail?.text.match(/\d{6}/)?.[0];
  if (!code) throw new Error(`No code sent to ${email}`);
  return code;
}

export interface TestUser {
  id: string;
  email: string;
  token: string;
  refreshToken: string;
  password: string;
}

let counter = 0;

export async function createUser(name = 'Tester'): Promise<TestUser> {
  const email = `user${++counter}-${Date.now()}@example.com`;
  const password = 'Secret123';
  await api().post('/auth/register').send({ email, password, displayName: name }).expect(201);
  const res = await api().post('/auth/verify-email').send({ email, code: lastCode(email) }).expect(200);
  return { id: res.body.user.id, email, token: res.body.accessToken, refreshToken: res.body.refreshToken, password };
}

export const auth = (user: TestUser) => ({ Authorization: `Bearer ${user.token}` });

export function eventPayload(overrides: Record<string, unknown> = {}) {
  return {
    id: randomUUID(),
    title: 'Spotkanie',
    startAt: '2026-08-14T10:00:00.000Z',
    endAt: '2026-08-14T11:30:00.000Z',
    allDay: false,
    color: '#87CEEB',
    ...overrides,
  };
}

export async function createGroup(owner: TestUser, name = 'Design Team') {
  const res = await api().post('/groups').set(auth(owner)).send({ name }).expect(201);
  return res.body as { id: string; inviteCode: string };
}

export async function joinGroup(user: TestUser, inviteCode: string) {
  await api().post('/groups/join').set(auth(user)).send({ code: inviteCode }).expect(201);
}
