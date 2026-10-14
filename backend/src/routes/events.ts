import { Prisma, type Event } from '@prisma/client';
import { Router } from 'express';
import { z } from 'zod';
import { prisma } from '../db.js';
import { badRequest, conflict, forbidden, notFound } from '../lib/errors.js';
import { dateKey, hexColor, isoDate } from '../lib/schemas.js';
import { serializeEvent } from '../lib/serializers.js';
import { parse } from '../lib/validate.js';
import { requireAuth, uid } from '../middleware/auth.js';
import { realtime } from '../realtime/io.js';
import { notifyEventsCreated, notifyEventUpdated } from '../services/notifications.js';
import { canEditEvent, canReadEvent, requireMember } from '../services/permissions.js';

export const eventsRouter = Router();
eventsRouter.use(requireAuth);

const MAX_BATCH = 100;

const recurrenceSchema = z
  .object({
    freq: z.enum(['daily', 'weekly', 'monthly', 'yearly']),
    interval: z.int().min(1).max(99),
    /** Ostatni dzień serii (włącznie), lokalna data kalendarzowa. */
    until: dateKey.nullish(),
    count: z.int().min(1).max(999).nullish(),
    /** ISO: 1 = poniedziałek … 7 = niedziela. */
    byWeekDay: z.array(z.int().min(1).max(7)).min(1).max(7).nullish(),
    byMonthDay: z.array(z.int().min(1).max(31)).min(1).max(31).nullish(),
  })
  .refine((r) => !(r.until && r.count), { message: 'Use either "until" or "count", not both' });

const fields = {
  title: z.string().trim().min(1).max(200),
  description: z.string().max(2000).nullish(),
  location: z.string().trim().max(200).nullish(),
  groupId: z.uuid().nullish(),
  startAt: isoDate,
  endAt: isoDate.nullish(),
  allDay: z.boolean(),
  color: hexColor,
  recurrence: recurrenceSchema.nullish(),
};

const createSchema = z.object({
  ...fields,
  id: z.uuid(),
  allDay: fields.allDay.default(false),
  color: fields.color.default('#87CEEB'),
});
// Bez wartości domyślnych — PATCH zmienia tylko przesłane pola (field-level last-write-wins).
const updateSchema = z.object(fields).partial();

type CreateInput = z.infer<typeof createSchema>;
type Recurrence = z.infer<typeof recurrenceSchema>;

const include = { exceptions: true } as const;
const idParam = z.object({ id: z.uuid() });

/** Wydarzenie całodniowe = data kalendarzowa zapisana jako północ UTC. */
const toUtcMidnight = (date: Date) => new Date(date.toISOString().slice(0, 10) + 'T00:00:00.000Z');

interface Normalized {
  startAt: Date;
  endAt: Date | null;
  allDay: boolean;
  recurrence: Recurrence | null;
}

function normalizeSchedule(input: {
  startAt: string | Date;
  endAt?: string | Date | null;
  allDay: boolean;
  recurrence?: Recurrence | null;
}): Normalized {
  let startAt = new Date(input.startAt);
  let endAt = input.endAt ? new Date(input.endAt) : null;
  if (input.allDay) {
    startAt = toUtcMidnight(startAt);
    endAt = endAt ? toUtcMidnight(endAt) : null;
  }
  if (endAt && endAt < startAt) throw badRequest('END_BEFORE_START', 'End date must not be before start date');

  const recurrence = input.recurrence ?? null;
  if (recurrence?.until) {
    // Tolerancja jednego dnia: serwer nie zna strefy czasowej klienta.
    const earliest = new Date(startAt.getTime() - 86_400_000).toISOString().slice(0, 10);
    if (recurrence.until < earliest) throw badRequest('UNTIL_BEFORE_START', 'Series end must not be before its start');
  }
  return { startAt, endAt, allDay: input.allDay, recurrence };
}

const recurrenceValue = (r: Recurrence | null): Prisma.InputJsonValue | typeof Prisma.DbNull =>
  r === null ? Prisma.DbNull : (r as Prisma.InputJsonValue);

async function loadEditable(id: string, userId: string) {
  const event = await prisma.event.findUnique({ where: { id }, include });
  if (!event || !(await canReadEvent(event, userId))) throw notFound('EVENT_NOT_FOUND');
  if (!(await canEditEvent(event, userId))) throw forbidden('NOT_EVENT_OWNER', 'Only the author or a group admin can change this event');
  return event;
}

function emitUpsert(event: Event & { exceptions: Prisma.EventExceptionGetPayload<object>[] }, actorId: string) {
  realtime.toEventAudience(event.groupId, event.createdById, 'event:upsert', { event: serializeEvent(event), actorId });
}

function emitDelete(event: Pick<Event, 'id' | 'groupId' | 'createdById'>, actorId: string, groupId = event.groupId) {
  realtime.toEventAudience(groupId, event.createdById, 'event:delete', { id: event.id, groupId, actorId });
}

async function createEvents(userId: string, inputs: CreateInput[]) {
  const groupIds = [...new Set(inputs.map((e) => e.groupId).filter((g): g is string => !!g))];
  for (const groupId of groupIds) await requireMember(groupId, userId);

  const ids = inputs.map((e) => e.id);
  if (new Set(ids).size !== ids.length) throw badRequest('DUPLICATE_ID');
  const existing = await prisma.event.findMany({ where: { id: { in: ids } }, select: { id: true, createdById: true } });
  if (existing.some((e) => e.createdById !== userId)) throw conflict('ID_CONFLICT');
  // Idempotencja: ponowione żądanie (np. po zerwanym połączeniu) nie tworzy duplikatów.
  const existingIds = new Set(existing.map((e) => e.id));
  const toCreate = inputs.filter((e) => !existingIds.has(e.id));

  const now = new Date();
  const data: Prisma.EventCreateManyInput[] = toCreate.map((input) => {
    const schedule = normalizeSchedule(input);
    return {
      id: input.id,
      title: input.title,
      description: input.description || null,
      location: input.location || null,
      groupId: input.groupId ?? null,
      color: input.color,
      createdById: userId,
      startAt: schedule.startAt,
      endAt: schedule.endAt,
      allDay: schedule.allDay,
      recurrence: recurrenceValue(schedule.recurrence),
      createdAt: now,
      updatedAt: now,
    };
  });
  if (data.length) await prisma.event.createMany({ data });

  const events = await prisma.event.findMany({ where: { id: { in: ids } }, include });
  const order = new Map(ids.map((id, i) => [id, i]));
  events.sort((a, b) => order.get(a.id)! - order.get(b.id)!);

  const created = events.filter((e) => !existingIds.has(e.id));
  for (const e of created) emitUpsert(e, userId);
  const byGroup = new Map<string, Event[]>();
  for (const e of created) if (e.groupId) byGroup.set(e.groupId, [...(byGroup.get(e.groupId) ?? []), e]);
  for (const group of byGroup.values()) notifyEventsCreated(group, userId);
  return events;
}

eventsRouter.get('/', async (req, res) => {
  const userId = uid(req);
  const query = parse(z.object({ from: isoDate.optional(), to: isoDate.optional() }), req.query);
  const memberships = await prisma.groupMember.findMany({ where: { userId }, select: { groupId: true } });
  const where: Prisma.EventWhereInput = {
    OR: [{ groupId: null, createdById: userId }, { groupId: { in: memberships.map((m) => m.groupId) } }],
  };
  if (query.from || query.to) {
    // Wydarzenia powtarzające się zawsze zwracamy (instancje generuje klient).
    where.AND = [
      {
        OR: [
          { recurrence: { not: Prisma.AnyNull } },
          {
            ...(query.to ? { startAt: { lte: new Date(query.to) } } : {}),
            ...(query.from
              ? { OR: [{ endAt: { gte: new Date(query.from) } }, { endAt: null, startAt: { gte: new Date(query.from) } }] }
              : {}),
          },
        ],
      },
    ];
  }
  const events = await prisma.event.findMany({ where, include, orderBy: { startAt: 'asc' } });
  res.json(events.map(serializeEvent));
});

eventsRouter.get('/:id', async (req, res) => {
  const { id } = parse(idParam, req.params);
  const event = await prisma.event.findUnique({ where: { id }, include });
  if (!event || !(await canReadEvent(event, uid(req)))) throw notFound('EVENT_NOT_FOUND');
  res.json(serializeEvent(event));
});

eventsRouter.post('/', async (req, res) => {
  const input = parse(createSchema, req.body);
  const [event] = await createEvents(uid(req), [input]);
  res.status(201).json(serializeEvent(event!));
});

/** Wiele wydarzeń naraz — używane przez tryb malowania. */
eventsRouter.post('/batch', async (req, res) => {
  const body = parse(z.object({ events: z.array(createSchema).min(1).max(MAX_BATCH) }), req.body);
  const events = await createEvents(uid(req), body.events);
  res.status(201).json(events.map(serializeEvent));
});

eventsRouter.post('/batch-delete', async (req, res) => {
  const userId = uid(req);
  const body = parse(z.object({ ids: z.array(z.uuid()).min(1).max(MAX_BATCH) }), req.body);
  const events = await prisma.event.findMany({ where: { id: { in: body.ids } } });
  const allowed: Event[] = [];
  for (const e of events) if (await canEditEvent(e, userId)) allowed.push(e);
  await prisma.$transaction([
    prisma.eventTombstone.createMany({
      data: allowed.map((e) => ({ eventId: e.id, groupId: e.groupId, ownerId: e.createdById })),
    }),
    prisma.event.deleteMany({ where: { id: { in: allowed.map((e) => e.id) } } }),
  ]);
  for (const e of allowed) emitDelete(e, userId);
  const allowedIds = new Set(allowed.map((e) => e.id));
  // Nieistniejące = już usunięte (idempotencja); istniejące bez uprawnień = odrzucone.
  const missing = body.ids.filter((id) => !events.some((e) => e.id === id));
  res.json({
    deleted: [...allowedIds, ...missing],
    forbidden: events.filter((e) => !allowedIds.has(e.id)).map((e) => e.id),
  });
});

eventsRouter.patch('/:id', async (req, res) => {
  const userId = uid(req);
  const { id } = parse(idParam, req.params);
  const input = parse(updateSchema, req.body);
  const current = await loadEditable(id, userId);

  const targetGroupId = input.groupId === undefined ? current.groupId : input.groupId;
  const groupChanged = targetGroupId !== current.groupId;
  if (groupChanged && targetGroupId) await requireMember(targetGroupId, userId);

  const schedule = normalizeSchedule({
    startAt: input.startAt ?? current.startAt,
    endAt: input.endAt === undefined ? current.endAt : input.endAt,
    allDay: input.allDay ?? current.allDay,
    recurrence: input.recurrence === undefined ? (current.recurrence as Recurrence | null) : input.recurrence,
  });

  const data: Prisma.EventUpdateInput = {
    version: { increment: 1 },
    updatedAt: new Date(),
    title: input.title,
    color: input.color,
    description: input.description === undefined ? undefined : input.description || null,
    location: input.location === undefined ? undefined : input.location || null,
    group: groupChanged ? (targetGroupId ? { connect: { id: targetGroupId } } : { disconnect: true }) : undefined,
  };
  if (input.startAt !== undefined || input.allDay !== undefined) data.startAt = schedule.startAt;
  if (input.endAt !== undefined || input.allDay !== undefined) data.endAt = schedule.endAt;
  if (input.allDay !== undefined) data.allDay = schedule.allDay;
  if (input.recurrence !== undefined) data.recurrence = recurrenceValue(schedule.recurrence);

  const updated = await prisma.$transaction(async (tx) => {
    if (groupChanged && current.groupId) {
      // Członkowie poprzedniej grupy muszą usunąć wydarzenie u siebie (także przy synchronizacji offline).
      await tx.eventTombstone.create({ data: { eventId: id, groupId: current.groupId } });
    }
    return tx.event.update({ where: { id }, data, include });
  });

  if (groupChanged && current.groupId) emitDelete(current, userId, current.groupId);
  emitUpsert(updated, userId);
  if (groupChanged && updated.groupId) notifyEventsCreated([updated], userId);
  else notifyEventUpdated(updated, userId);
  res.json(serializeEvent(updated));
});

eventsRouter.delete('/:id', async (req, res) => {
  const userId = uid(req);
  const { id } = parse(idParam, req.params);
  const event = await prisma.event.findUnique({ where: { id } });
  if (!event) {
    res.json({ ok: true }); // już usunięte — idempotencja dla kolejki offline
    return;
  }
  await loadEditable(id, userId);
  await prisma.$transaction([
    prisma.eventTombstone.create({ data: { eventId: id, groupId: event.groupId, ownerId: event.createdById } }),
    prisma.event.delete({ where: { id } }),
  ]);
  emitDelete(event, userId);
  res.json({ ok: true });
});

// --- Wyjątki pojedynczych wystąpień serii ---

const exceptionParams = z.object({ id: z.uuid(), date: dateKey });
const exceptionBody = z.object({
  cancelled: z.boolean().default(false),
  title: z.string().trim().min(1).max(200).nullish(),
  color: hexColor.nullish(),
  startAt: isoDate.nullish(),
  endAt: isoDate.nullish(),
});

eventsRouter.put('/:id/exceptions/:date', async (req, res) => {
  const userId = uid(req);
  const params = parse(exceptionParams, req.params);
  const body = parse(exceptionBody, req.body);
  const event = await loadEditable(params.id, userId);
  if (!event.recurrence) throw badRequest('NOT_RECURRING', 'Only recurring events have exceptions');
  if (body.startAt && body.endAt && new Date(body.endAt) < new Date(body.startAt)) throw badRequest('END_BEFORE_START');

  const values = {
    cancelled: body.cancelled,
    title: body.title ?? null,
    color: body.color ?? null,
    startAt: body.startAt ? new Date(body.startAt) : null,
    endAt: body.endAt ? new Date(body.endAt) : null,
  };
  const updated = await prisma.event.update({
    where: { id: params.id },
    data: {
      version: { increment: 1 },
      updatedAt: new Date(),
      exceptions: {
        upsert: {
          where: { eventId_originalDate: { eventId: params.id, originalDate: params.date } },
          create: { originalDate: params.date, ...values },
          update: values,
        },
      },
    },
    include,
  });
  emitUpsert(updated, userId);
  res.json(serializeEvent(updated));
});

eventsRouter.delete('/:id/exceptions/:date', async (req, res) => {
  const userId = uid(req);
  const params = parse(exceptionParams, req.params);
  await loadEditable(params.id, userId);
  const updated = await prisma.event.update({
    where: { id: params.id },
    data: {
      version: { increment: 1 },
      updatedAt: new Date(),
      exceptions: { deleteMany: { originalDate: params.date } },
    },
    include,
  });
  emitUpsert(updated, userId);
  res.json(serializeEvent(updated));
});
