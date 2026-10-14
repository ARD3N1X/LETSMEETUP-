import type { Event } from '@prisma/client';
import { prisma } from '../db.js';
import { forbidden, notFound } from '../lib/errors.js';

export async function getMembership(groupId: string, userId: string) {
  return prisma.groupMember.findUnique({ where: { groupId_userId: { groupId, userId } } });
}

export async function requireMember(groupId: string, userId: string) {
  const membership = await getMembership(groupId, userId);
  // 404 zamiast 403 — nie zdradzamy istnienia cudzych grup.
  if (!membership) throw notFound('GROUP_NOT_FOUND');
  return membership;
}

export async function requireAdmin(groupId: string, userId: string) {
  const membership = await requireMember(groupId, userId);
  if (membership.role !== 'admin') throw forbidden('ADMIN_ONLY');
  return membership;
}

export async function canReadEvent(event: Event, userId: string) {
  if (event.groupId === null) return event.createdById === userId;
  return (await getMembership(event.groupId, userId)) !== null;
}

/** Edycja/usunięcie: autor (o ile nadal ma dostęp) lub admin grupy. */
export async function canEditEvent(event: Event, userId: string) {
  if (event.groupId === null) return event.createdById === userId;
  const membership = await getMembership(event.groupId, userId);
  if (!membership) return false;
  return event.createdById === userId || membership.role === 'admin';
}
