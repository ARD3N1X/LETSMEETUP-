import { Router } from 'express';
import { z } from 'zod';
import { config } from '../config.js';
import { prisma } from '../db.js';
import { isoDate } from '../lib/schemas.js';
import { groupInclude, serializeEvent, serializeGroup } from '../lib/serializers.js';
import { parse } from '../lib/validate.js';
import { requireAuth, uid } from '../middleware/auth.js';

export const syncRouter = Router();
syncRouter.use(requireAuth);

/** Zakładka czasowa — zapis zatwierdzony tuż po naszym odczycie mógł mieć wcześniejszy updatedAt. */
const OVERLAP_MS = 5_000;

/**
 * GET /sync?since=<serverTime z poprzedniej odpowiedzi>
 *
 * Zwraca: pełną listę grup użytkownika (klient usuwa lokalnie wydarzenia grup, których już nie ma),
 * zmienione wydarzenia oraz identyfikatory usuniętych. Bez `since` (lub ze zbyt starym) → pełny zrzut.
 * Klient stosuje najpierw `deletedEventIds`, potem `events`.
 */
syncRouter.get('/', async (req, res) => {
  const userId = uid(req);
  const query = parse(z.object({ since: isoDate.optional() }), req.query);
  const serverTime = new Date();

  const retentionLimit = new Date(serverTime.getTime() - config.tombstoneRetentionDays * 86_400_000);
  const since = query.since ? new Date(new Date(query.since).getTime() - OVERLAP_MS) : null;
  const full = !since || since < retentionLimit;

  const groups = await prisma.group.findMany({
    where: { members: { some: { userId } } },
    include: groupInclude,
    orderBy: { name: 'asc' },
  });
  const groupIds = groups.map((g) => g.id);
  const accessible = [{ groupId: null, createdById: userId }, { groupId: { in: groupIds } }];

  let events;
  let deletedEventIds: string[] = [];
  if (full) {
    events = await prisma.event.findMany({ where: { OR: accessible }, include: { exceptions: true } });
  } else {
    // Po dołączeniu do grupy trzeba pobrać także jej starsze wydarzenia.
    const newlyJoined = groups
      .filter((g) => g.members.some((m) => m.userId === userId && m.joinedAt >= since))
      .map((g) => g.id);
    events = await prisma.event.findMany({
      where: {
        AND: [{ OR: accessible }, { OR: [{ updatedAt: { gte: since } }, { groupId: { in: newlyJoined } }] }],
      },
      include: { exceptions: true },
    });
    const tombstones = await prisma.eventTombstone.findMany({
      where: { deletedAt: { gte: since }, OR: [{ groupId: { in: groupIds } }, { ownerId: userId }] },
      select: { eventId: true },
    });
    const stillVisible = new Set(events.map((e) => e.id));
    deletedEventIds = [...new Set(tombstones.map((t) => t.eventId))].filter((id) => !stillVisible.has(id));
  }

  res.json({
    serverTime: serverTime.toISOString(),
    full,
    groups: groups.map((g) => serializeGroup(g, userId)),
    events: events.map(serializeEvent),
    deletedEventIds,
  });
});
