import bcrypt from 'bcryptjs';
import { Router } from 'express';
import multer from 'multer';
import sharp from 'sharp';
import { z } from 'zod';
import { prisma } from '../db.js';
import { badRequest, unauthorized } from '../lib/errors.js';
import { displayName, hexColor, password } from '../lib/schemas.js';
import { serializeMe } from '../lib/serializers.js';
import { parse } from '../lib/validate.js';
import { requireAuth, uid } from '../middleware/auth.js';
import { realtime } from '../realtime/io.js';

export const meRouter = Router();
meRouter.use(requireAuth);

const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 5 * 1024 * 1024 },
});

/** Adres avatara z wersją — zmiana zdjęcia omija cache (CachedNetworkImage, CDN). */
const avatarPath = (userId: string) => `/avatars/${userId}?v=${Date.now()}`;

meRouter.get('/', async (req, res) => {
  const user = await prisma.user.findUnique({ where: { id: uid(req) } });
  if (!user) throw unauthorized('USER_NOT_FOUND');
  res.json(serializeMe(user));
});

const settingsSchema = z
  .object({
    themeMode: z.enum(['system', 'light', 'dark']),
    accentColor: hexColor,
    defaultEventColor: hexColor,
    language: z.enum(['pl', 'en']),
    pushEnabled: z.boolean(),
    remindersEnabled: z.boolean(),
    defaultReminderMinutes: z.int().min(0).max(10_080),
  })
  .partial();

meRouter.patch('/', async (req, res) => {
  const body = parse(z.object({ displayName: displayName.optional(), settings: settingsSchema.optional() }), req.body);
  const user = await prisma.user.update({
    where: { id: uid(req) },
    data: { displayName: body.displayName, ...body.settings },
  });
  // Inni członkowie grup muszą zobaczyć nowe imię.
  if (body.displayName) await notifyGroupsChanged(user.id);
  res.json(serializeMe(user));
});

meRouter.post('/avatar', upload.single('avatar'), async (req, res) => {
  if (!req.file) throw badRequest('MISSING_FILE', 'Field "avatar" with an image is required');
  let image: Buffer;
  try {
    image = await sharp(req.file.buffer).rotate().resize(256, 256, { fit: 'cover' }).webp({ quality: 85 }).toBuffer();
  } catch {
    throw badRequest('INVALID_IMAGE', 'Unsupported image');
  }
  const userId = uid(req);
  const data = new Uint8Array(image);
  const [, user] = await prisma.$transaction([
    prisma.avatar.upsert({ where: { userId }, create: { userId, data }, update: { data } }),
    prisma.user.update({ where: { id: userId }, data: { avatarUrl: avatarPath(userId) } }),
  ]);
  await notifyGroupsChanged(userId);
  res.json(serializeMe(user));
});

meRouter.delete('/avatar', async (req, res) => {
  const userId = uid(req);
  const [, user] = await prisma.$transaction([
    prisma.avatar.deleteMany({ where: { userId } }),
    prisma.user.update({ where: { id: userId }, data: { avatarUrl: null } }),
  ]);
  await notifyGroupsChanged(userId);
  res.json(serializeMe(user));
});

meRouter.post('/devices', async (req, res) => {
  const body = parse(
    z.object({ token: z.string().min(10).max(4096), platform: z.enum(['android', 'ios', 'web', 'other']) }),
    req.body,
  );
  const userId = uid(req);
  await prisma.deviceToken.upsert({
    where: { token: body.token },
    create: { token: body.token, platform: body.platform, userId },
    update: { userId, platform: body.platform },
  });
  res.json({ ok: true });
});

meRouter.delete('/devices', async (req, res) => {
  const body = parse(z.object({ token: z.string().min(10).max(4096) }), req.body);
  await prisma.deviceToken.deleteMany({ where: { token: body.token, userId: uid(req) } });
  res.json({ ok: true });
});

meRouter.post('/password', async (req, res) => {
  const body = parse(z.object({ currentPassword: z.string().min(1), newPassword: password }), req.body);
  const userId = uid(req);
  const user = await prisma.user.findUniqueOrThrow({ where: { id: userId } });
  if (!(await bcrypt.compare(body.currentPassword, user.passwordHash))) throw badRequest('INVALID_PASSWORD');
  await prisma.user.update({ where: { id: userId }, data: { passwordHash: await bcrypt.hash(body.newPassword, 12) } });
  res.json({ ok: true });
});

/** Usunięcie konta (wymagane m.in. przez App Store). */
meRouter.delete('/', async (req, res) => {
  const body = parse(z.object({ password: z.string().min(1) }), req.body);
  const userId = uid(req);
  const user = await prisma.user.findUniqueOrThrow({ where: { id: userId } });
  if (!(await bcrypt.compare(body.password, user.passwordHash))) throw badRequest('INVALID_PASSWORD');

  const memberships = await prisma.groupMember.findMany({
    where: { userId },
    include: { group: { include: { members: { orderBy: { joinedAt: 'asc' } } } } },
  });
  const events = await prisma.event.findMany({ where: { createdById: userId }, select: { id: true, groupId: true } });

  await prisma.$transaction(async (tx) => {
    for (const m of memberships) {
      const others = m.group.members.filter((x) => x.userId !== userId);
      if (others.length === 0) {
        await tx.group.delete({ where: { id: m.groupId } });
      } else if (m.role === 'admin' && !others.some((x) => x.role === 'admin')) {
        // Grupa nie może zostać bez admina — rolę dostaje najdłużej obecny członek.
        await tx.groupMember.update({ where: { id: others[0]!.id }, data: { role: 'admin' } });
      }
      // Grupy mają FK created_by → przenosimy "autorstwo" grupy.
      if (others.length > 0 && m.group.createdById === userId) {
        await tx.group.update({ where: { id: m.groupId }, data: { createdById: others[0]!.userId } });
      }
    }
    await tx.eventTombstone.createMany({
      data: events.map((e) => ({ eventId: e.id, groupId: e.groupId, ownerId: userId })),
    });
    await tx.user.delete({ where: { id: userId } });
  });

  for (const e of events) if (e.groupId) realtime.toGroup(e.groupId, 'event:delete', { id: e.id, groupId: e.groupId, actorId: userId });
  for (const m of memberships) realtime.toGroup(m.groupId, 'groups:changed');
  res.json({ ok: true });
});

async function notifyGroupsChanged(userId: string) {
  const memberships = await prisma.groupMember.findMany({ where: { userId }, select: { groupId: true } });
  for (const m of memberships) realtime.toGroup(m.groupId, 'groups:changed');
  realtime.toUser(userId, 'groups:changed');
}
