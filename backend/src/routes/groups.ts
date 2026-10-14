import bcrypt from 'bcryptjs';
import { Prisma } from '@prisma/client';
import { Router } from 'express';
import { z } from 'zod';
import { config } from '../config.js';
import { prisma } from '../db.js';
import { randomInviteCode } from '../lib/crypto.js';
import { badRequest, conflict, notFound } from '../lib/errors.js';
import { hexColor } from '../lib/schemas.js';
import { groupInclude, serializeGroup } from '../lib/serializers.js';
import { parse } from '../lib/validate.js';
import { requireAuth, uid } from '../middleware/auth.js';
import { codeLimiter } from '../middleware/rate-limit.js';
import { realtime } from '../realtime/io.js';
import { notifyMemberJoined } from '../services/notifications.js';
import { requireAdmin, requireMember } from '../services/permissions.js';

export const groupsRouter = Router();
groupsRouter.use(requireAuth);

const groupFields = z.object({
  name: z.string().trim().min(1).max(100),
  description: z.string().trim().max(500).nullish(),
  color: hexColor.optional(),
});

const idParam = z.object({ id: z.uuid() });
const memberParams = z.object({ id: z.uuid(), userId: z.uuid() });

async function loadGroup(groupId: string, viewerId: string) {
  const group = await prisma.group.findUniqueOrThrow({ where: { id: groupId }, include: groupInclude });
  return serializeGroup(group, viewerId);
}

/** Generuje unikalny kod zaproszenia (ponawia przy rzadkiej kolizji). */
async function withUniqueInviteCode<T>(action: (code: string) => Promise<T>): Promise<T> {
  for (let attempt = 0; attempt < 5; attempt++) {
    try {
      return await action(randomInviteCode());
    } catch (err) {
      const isCollision =
        err instanceof Prisma.PrismaClientKnownRequestError &&
        err.code === 'P2002' &&
        JSON.stringify(err.meta?.target ?? '').includes('invite_code');
      if (!isCollision) throw err;
    }
  }
  throw conflict('INVITE_CODE_GENERATION_FAILED');
}

async function ensureCanJoinMoreGroups(userId: string) {
  const count = await prisma.groupMember.count({ where: { userId } });
  if (count >= config.maxGroupsPerUser) {
    throw conflict('TOO_MANY_GROUPS', `You can belong to at most ${config.maxGroupsPerUser} groups`);
  }
}

groupsRouter.get('/', async (req, res) => {
  const userId = uid(req);
  const groups = await prisma.group.findMany({
    where: { members: { some: { userId } } },
    include: groupInclude,
    orderBy: { name: 'asc' },
  });
  res.json(groups.map((g) => serializeGroup(g, userId)));
});

groupsRouter.post('/', async (req, res) => {
  const userId = uid(req);
  const body = parse(groupFields, req.body);
  await ensureCanJoinMoreGroups(userId);
  const group = await withUniqueInviteCode((inviteCode) =>
    prisma.group.create({
      data: {
        name: body.name,
        description: body.description || null,
        color: body.color,
        inviteCode,
        createdById: userId,
        members: { create: { userId, role: 'admin' } },
      },
      include: groupInclude,
    }),
  );
  realtime.joinGroup(userId, group.id);
  realtime.toUser(userId, 'groups:changed');
  res.status(201).json(serializeGroup(group, userId));
});

groupsRouter.post('/join', codeLimiter, async (req, res) => {
  const userId = uid(req);
  const body = parse(z.object({ code: z.string().trim().min(4).max(20) }), req.body);
  const code = body.code.toUpperCase().replace(/[\s-]/g, '');
  const group = await prisma.group.findUnique({ where: { inviteCode: code }, include: { members: true } });
  if (!group) throw notFound('INVALID_INVITE_CODE', 'Invite code not found');
  if (group.members.some((m) => m.userId === userId)) throw conflict('ALREADY_MEMBER');
  if (group.members.length >= config.maxGroupMembers) throw conflict('GROUP_FULL');
  await ensureCanJoinMoreGroups(userId);

  await prisma.groupMember.create({ data: { groupId: group.id, userId, role: 'member' } });
  realtime.joinGroup(userId, group.id);
  realtime.toGroup(group.id, 'groups:changed');
  notifyMemberJoined(group.id, userId);
  res.status(201).json(await loadGroup(group.id, userId));
});

groupsRouter.get('/:id', async (req, res) => {
  const { id } = parse(idParam, req.params);
  const userId = uid(req);
  await requireMember(id, userId);
  res.json(await loadGroup(id, userId));
});

groupsRouter.patch('/:id', async (req, res) => {
  const { id } = parse(idParam, req.params);
  const userId = uid(req);
  await requireAdmin(id, userId);
  const body = parse(groupFields.partial(), req.body);
  await prisma.group.update({
    where: { id },
    data: {
      name: body.name,
      description: body.description === undefined ? undefined : body.description || null,
      color: body.color,
    },
  });
  realtime.toGroup(id, 'groups:changed');
  res.json(await loadGroup(id, userId));
});

groupsRouter.delete('/:id', async (req, res) => {
  const { id } = parse(idParam, req.params);
  const userId = uid(req);
  await requireAdmin(id, userId);
  const body = parse(z.object({ password: z.string().min(1) }), req.body ?? {});
  const user = await prisma.user.findUniqueOrThrow({ where: { id: userId } });
  if (!(await bcrypt.compare(body.password, user.passwordHash))) throw badRequest('INVALID_PASSWORD');

  await prisma.group.delete({ where: { id } });
  realtime.toGroup(id, 'group:removed', { groupId: id });
  realtime.closeGroup(id);
  res.json({ ok: true });
});

groupsRouter.post('/:id/invite-code', async (req, res) => {
  const { id } = parse(idParam, req.params);
  const userId = uid(req);
  await requireAdmin(id, userId);
  await withUniqueInviteCode((inviteCode) => prisma.group.update({ where: { id }, data: { inviteCode } }));
  realtime.toGroup(id, 'groups:changed');
  res.json(await loadGroup(id, userId));
});

groupsRouter.post('/:id/leave', async (req, res) => {
  const { id } = parse(idParam, req.params);
  const userId = uid(req);
  const membership = await requireMember(id, userId);
  const members = await prisma.groupMember.findMany({ where: { groupId: id } });

  if (members.length === 1) {
    // Ostatni członek opuszcza grupę → grupa przestaje istnieć.
    await prisma.group.delete({ where: { id } });
    realtime.toUser(userId, 'group:removed', { groupId: id });
    realtime.closeGroup(id);
    res.json({ ok: true, groupDeleted: true });
    return;
  }
  const admins = members.filter((m) => m.role === 'admin');
  if (membership.role === 'admin' && admins.length === 1) {
    throw conflict('LAST_ADMIN', 'Transfer the admin role to another member before leaving');
  }
  await prisma.groupMember.delete({ where: { id: membership.id } });
  realtime.leaveGroup(userId, id);
  realtime.toUser(userId, 'group:removed', { groupId: id });
  realtime.toGroup(id, 'groups:changed');
  res.json({ ok: true, groupDeleted: false });
});

groupsRouter.patch('/:id/members/:userId', async (req, res) => {
  const params = parse(memberParams, req.params);
  const actorId = uid(req);
  await requireAdmin(params.id, actorId);
  const body = parse(z.object({ role: z.enum(['admin', 'member']) }), req.body);
  const target = await prisma.groupMember.findUnique({
    where: { groupId_userId: { groupId: params.id, userId: params.userId } },
  });
  if (!target) throw notFound('MEMBER_NOT_FOUND');
  if (target.role === 'admin' && body.role === 'member') {
    const adminCount = await prisma.groupMember.count({ where: { groupId: params.id, role: 'admin' } });
    if (adminCount === 1) throw conflict('LAST_ADMIN', 'A group must have at least one admin');
  }
  await prisma.groupMember.update({ where: { id: target.id }, data: { role: body.role } });
  realtime.toGroup(params.id, 'groups:changed');
  res.json(await loadGroup(params.id, actorId));
});

groupsRouter.delete('/:id/members/:userId', async (req, res) => {
  const params = parse(memberParams, req.params);
  const actorId = uid(req);
  await requireAdmin(params.id, actorId);
  if (params.userId === actorId) throw badRequest('CANNOT_REMOVE_SELF', 'Use "leave group" instead');
  const target = await prisma.groupMember.findUnique({
    where: { groupId_userId: { groupId: params.id, userId: params.userId } },
  });
  if (!target) throw notFound('MEMBER_NOT_FOUND');
  await prisma.groupMember.delete({ where: { id: target.id } });
  realtime.leaveGroup(params.userId, params.id);
  realtime.toUser(params.userId, 'group:removed', { groupId: params.id });
  realtime.toGroup(params.id, 'groups:changed');
  res.json(await loadGroup(params.id, actorId));
});
