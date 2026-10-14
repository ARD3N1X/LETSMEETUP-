import type { Event } from '@prisma/client';
import { prisma } from '../db.js';
import { logger } from '../lib/logger.js';
import { sendPush } from '../lib/push.js';

const dateKey = (event: Event) => event.startAt.toISOString().slice(0, 10);

async function context(groupId: string, actorId: string) {
  const [group, actor] = await Promise.all([
    prisma.group.findUnique({ where: { id: groupId }, include: { members: true } }),
    prisma.user.findUnique({ where: { id: actorId }, select: { displayName: true } }),
  ]);
  return { group, actorName: actor?.displayName ?? '?' };
}

function fireAndForget(task: Promise<void>) {
  task.catch((err) => logger.error({ err }, 'Push notification failed'));
}

export function notifyEventsCreated(events: Event[], actorId: string) {
  const first = events[0];
  if (!first?.groupId) return;
  const groupId = first.groupId;
  fireAndForget(
    (async () => {
      const { group, actorName } = await context(groupId, actorId);
      if (!group) return;
      const recipients = group.members.map((m) => m.userId).filter((id) => id !== actorId);
      const many = events.length > 1;
      await sendPush(recipients, (lang) => ({
        title: lang === 'en' ? `New event in ${group.name}` : `Nowe wydarzenie w ${group.name}`,
        body: many
          ? lang === 'en'
            ? `${actorName} added ${events.length} events: ${first.title}`
            : `${actorName} dodał(a) ${events.length} wydarzeń: ${first.title}`
          : lang === 'en'
            ? `${actorName} added: ${first.title}`
            : `${actorName} dodał(a) wydarzenie: ${first.title}`,
        data: { type: 'event_created', eventId: first.id, groupId, date: dateKey(first) },
      }));
    })(),
  );
}

export function notifyEventUpdated(event: Event, actorId: string) {
  if (!event.groupId) return;
  const groupId = event.groupId;
  fireAndForget(
    (async () => {
      const { group, actorName } = await context(groupId, actorId);
      if (!group) return;
      const recipients = group.members.map((m) => m.userId).filter((id) => id !== actorId);
      await sendPush(recipients, (lang) => ({
        title: group.name,
        body:
          lang === 'en'
            ? `${actorName} changed the event: ${event.title}`
            : `${actorName} zmienił(a) wydarzenie: ${event.title}`,
        data: { type: 'event_updated', eventId: event.id, groupId, date: dateKey(event) },
      }));
    })(),
  );
}

export function notifyMemberJoined(groupId: string, newMemberId: string) {
  fireAndForget(
    (async () => {
      const { group, actorName } = await context(groupId, newMemberId);
      if (!group) return;
      const admins = group.members.filter((m) => m.role === 'admin' && m.userId !== newMemberId).map((m) => m.userId);
      await sendPush(admins, (lang) => ({
        title: group.name,
        body: lang === 'en' ? `${actorName} joined the group` : `${actorName} dołączył(a) do grupy`,
        data: { type: 'member_joined', groupId },
      }));
    })(),
  );
}
