import { beforeEach, describe, expect, it } from 'vitest';
import { api, auth, createGroup, createUser, joinGroup, resetDb } from './helpers.js';

beforeEach(resetDb);

describe('groups', () => {
  it('creates a group with the creator as admin and an 8-char invite code', async () => {
    const owner = await createUser();
    const group = await createGroup(owner);
    expect(group.inviteCode).toMatch(/^[A-Z2-9]{8}$/);
    const res = await api().get(`/groups/${group.id}`).set(auth(owner)).expect(200);
    expect(res.body.myRole).toBe('admin');
    expect(res.body.memberCount).toBe(1);
  });

  it('joins by case-insensitive invite code, always as member', async () => {
    const owner = await createUser();
    const member = await createUser();
    const group = await createGroup(owner);

    const res = await api()
      .post('/groups/join')
      .set(auth(member))
      .send({ code: group.inviteCode.toLowerCase() })
      .expect(201);
    expect(res.body.myRole).toBe('member');

    const again = await api().post('/groups/join').set(auth(member)).send({ code: group.inviteCode }).expect(409);
    expect(again.body.error.code).toBe('ALREADY_MEMBER');
    await api().post('/groups/join').set(auth(member)).send({ code: 'ZZZZZZZZ' }).expect(404);
  });

  it('enforces the member limit', async () => {
    const owner = await createUser();
    const group = await createGroup(owner);
    await joinGroup(await createUser(), group.inviteCode);
    await joinGroup(await createUser(), group.inviteCode);
    const res = await api().post('/groups/join').set(auth(await createUser())).send({ code: group.inviteCode }).expect(409);
    expect(res.body.error.code).toBe('GROUP_FULL');
  });

  it('hides groups from non-members', async () => {
    const owner = await createUser();
    const stranger = await createUser();
    const group = await createGroup(owner);
    await api().get(`/groups/${group.id}`).set(auth(stranger)).expect(404);
    await api().patch(`/groups/${group.id}`).set(auth(stranger)).send({ name: 'Hack' }).expect(404);
  });

  it('only admins can edit, regenerate the code and manage members', async () => {
    const owner = await createUser();
    const member = await createUser();
    const group = await createGroup(owner);
    await joinGroup(member, group.inviteCode);

    await api().patch(`/groups/${group.id}`).set(auth(member)).send({ name: 'X' }).expect(403);
    await api().post(`/groups/${group.id}/invite-code`).set(auth(member)).expect(403);

    const regenerated = await api().post(`/groups/${group.id}/invite-code`).set(auth(owner)).expect(200);
    expect(regenerated.body.inviteCode).not.toBe(group.inviteCode);

    await api().delete(`/groups/${group.id}/members/${owner.id}`).set(auth(owner)).expect(400);
    const removed = await api().delete(`/groups/${group.id}/members/${member.id}`).set(auth(owner)).expect(200);
    expect(removed.body.memberCount).toBe(1);
  });

  it('never leaves a group without an admin', async () => {
    const owner = await createUser();
    const member = await createUser();
    const group = await createGroup(owner);
    await joinGroup(member, group.inviteCode);

    const leave = await api().post(`/groups/${group.id}/leave`).set(auth(owner)).expect(409);
    expect(leave.body.error.code).toBe('LAST_ADMIN');
    await api().patch(`/groups/${group.id}/members/${owner.id}`).set(auth(owner)).send({ role: 'member' }).expect(409);

    await api().patch(`/groups/${group.id}/members/${member.id}`).set(auth(owner)).send({ role: 'admin' }).expect(200);
    await api().post(`/groups/${group.id}/leave`).set(auth(owner)).expect(200);
    const res = await api().get(`/groups/${group.id}`).set(auth(member)).expect(200);
    expect(res.body.members).toHaveLength(1);
  });

  it('deletes the group when the last member leaves', async () => {
    const owner = await createUser();
    const group = await createGroup(owner);
    const res = await api().post(`/groups/${group.id}/leave`).set(auth(owner)).expect(200);
    expect(res.body.groupDeleted).toBe(true);
    await api().get(`/groups/${group.id}`).set(auth(owner)).expect(404);
  });

  it('requires the password to delete a group', async () => {
    const owner = await createUser();
    const group = await createGroup(owner);
    await api().delete(`/groups/${group.id}`).set(auth(owner)).send({ password: 'wrong' }).expect(400);
    await api().delete(`/groups/${group.id}`).set(auth(owner)).send({ password: owner.password }).expect(200);
  });
});
