import { beforeEach, describe, expect, it } from 'vitest';
import { api, auth, createUser, lastCode, resetDb } from './helpers.js';

beforeEach(resetDb);

describe('auth', () => {
  it('rejects weak passwords', async () => {
    const res = await api()
      .post('/auth/register')
      .send({ email: 'weak@example.com', password: 'password', displayName: 'Ala' })
      .expect(400);
    expect(res.body.error.code).toBe('VALIDATION_ERROR');
  });

  it('requires e-mail verification before login', async () => {
    const email = 'Ala@Example.com';
    await api().post('/auth/register').send({ email, password: 'Secret123', displayName: 'Ala' }).expect(201);

    const blocked = await api().post('/auth/login').send({ email, password: 'Secret123' }).expect(403);
    expect(blocked.body.error.code).toBe('EMAIL_NOT_VERIFIED');

    await api().post('/auth/verify-email').send({ email, code: '000000' }).expect(400);
    const verified = await api()
      .post('/auth/verify-email')
      .send({ email, code: lastCode('ala@example.com') })
      .expect(200);
    expect(verified.body.user.email).toBe('ala@example.com');

    const login = await api().post('/auth/login').send({ email: 'ala@example.com', password: 'Secret123' }).expect(200);
    expect(login.body.accessToken).toBeTruthy();
    await api().get('/me').set({ Authorization: `Bearer ${login.body.accessToken}` }).expect(200);
  });

  it('does not allow registering a verified e-mail twice', async () => {
    const user = await createUser();
    const res = await api()
      .post('/auth/register')
      .send({ email: user.email, password: 'Other1234', displayName: 'X' })
      .expect(409);
    expect(res.body.error.code).toBe('EMAIL_TAKEN');
  });

  it('rotates refresh tokens and detects reuse', async () => {
    const user = await createUser();
    const first = await api().post('/auth/refresh').send({ refreshToken: user.refreshToken }).expect(200);
    expect(first.body.refreshToken).not.toBe(user.refreshToken);

    // Ponowne użycie starego tokenu unieważnia wszystkie sesje.
    await api().post('/auth/refresh').send({ refreshToken: user.refreshToken }).expect(401);
    await api().post('/auth/refresh').send({ refreshToken: first.body.refreshToken }).expect(401);
  });

  it('resets password with an e-mailed code', async () => {
    const user = await createUser();
    await api().post('/auth/forgot-password').send({ email: user.email }).expect(200);
    await api()
      .post('/auth/reset-password')
      .send({ email: user.email, code: lastCode(user.email), newPassword: 'NewSecret1' })
      .expect(200);
    await api().post('/auth/login').send({ email: user.email, password: user.password }).expect(401);
    await api().post('/auth/login').send({ email: user.email, password: 'NewSecret1' }).expect(200);
  });

  it('updates profile settings partially', async () => {
    const user = await createUser();
    const res = await api()
      .patch('/me')
      .set(auth(user))
      .send({ displayName: 'Nowe Imię', settings: { themeMode: 'dark', defaultReminderMinutes: 30 } })
      .expect(200);
    expect(res.body.displayName).toBe('Nowe Imię');
    expect(res.body.settings).toMatchObject({ themeMode: 'dark', defaultReminderMinutes: 30, language: 'pl' });
  });

  it('stores avatars in the database and serves them', async () => {
    const user = await createUser();
    const png = Buffer.from(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
      'base64',
    );
    const res = await api().post('/me/avatar').set(auth(user)).attach('avatar', png, 'a.png').expect(200);
    const path = new URL(res.body.avatarUrl, 'http://x').pathname + new URL(res.body.avatarUrl, 'http://x').search;
    const image = await api().get(path).expect(200);
    expect(image.headers['content-type']).toBe('image/webp');

    await api().delete('/me/avatar').set(auth(user)).expect(200);
    await api().get(path).expect(404);
  });

  it('rejects requests without a valid token', async () => {
    await api().get('/me').expect(401);
    await api().get('/me').set({ Authorization: 'Bearer nope' }).expect(401);
  });
});
