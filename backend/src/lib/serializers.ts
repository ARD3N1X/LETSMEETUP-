import type { Event, EventException, Group, GroupMember, User } from '@prisma/client';
import { config } from '../config.js';

export const avatarUrl = (path: string | null) =>
  path ? (path.startsWith('http') ? path : `${config.publicUrl}${path}`) : null;

export function serializeMe(user: User) {
  return {
    id: user.id,
    email: user.email,
    displayName: user.displayName,
    avatarUrl: avatarUrl(user.avatarUrl),
    emailVerified: user.emailVerifiedAt !== null,
    settings: {
      themeMode: user.themeMode,
      accentColor: user.accentColor,
      defaultEventColor: user.defaultEventColor,
      language: user.language,
      pushEnabled: user.pushEnabled,
      remindersEnabled: user.remindersEnabled,
      defaultReminderMinutes: user.defaultReminderMinutes,
    },
    createdAt: user.createdAt.toISOString(),
    updatedAt: user.updatedAt.toISOString(),
  };
}

type MemberWithUser = GroupMember & { user: Pick<User, 'id' | 'displayName' | 'avatarUrl'> };

export function serializeGroup(group: Group & { members: MemberWithUser[] }, viewerId: string) {
  const me = group.members.find((m) => m.userId === viewerId);
  return {
    id: group.id,
    name: group.name,
    description: group.description,
    color: group.color,
    inviteCode: group.inviteCode,
    createdById: group.createdById,
    myRole: me?.role ?? null,
    memberCount: group.members.length,
    members: group.members
      .slice()
      .sort((a, b) => a.joinedAt.getTime() - b.joinedAt.getTime())
      .map((m) => ({
        userId: m.userId,
        displayName: m.user.displayName,
        avatarUrl: avatarUrl(m.user.avatarUrl),
        role: m.role,
        joinedAt: m.joinedAt.toISOString(),
      })),
    createdAt: group.createdAt.toISOString(),
    updatedAt: group.updatedAt.toISOString(),
  };
}

export type SerializedGroup = ReturnType<typeof serializeGroup>;

export function serializeEvent(event: Event & { exceptions: EventException[] }) {
  return {
    id: event.id,
    title: event.title,
    description: event.description,
    location: event.location,
    createdById: event.createdById,
    groupId: event.groupId,
    startAt: event.startAt.toISOString(),
    endAt: event.endAt?.toISOString() ?? null,
    allDay: event.allDay,
    color: event.color,
    recurrence: event.recurrence ?? null,
    exceptions: event.exceptions
      .slice()
      .sort((a, b) => a.originalDate.localeCompare(b.originalDate))
      .map((x) => ({
        date: x.originalDate,
        cancelled: x.cancelled,
        title: x.title,
        color: x.color,
        startAt: x.startAt?.toISOString() ?? null,
        endAt: x.endAt?.toISOString() ?? null,
      })),
    version: event.version,
    createdAt: event.createdAt.toISOString(),
    updatedAt: event.updatedAt.toISOString(),
  };
}

export type SerializedEvent = ReturnType<typeof serializeEvent>;

export const groupInclude = {
  members: { include: { user: { select: { id: true, displayName: true, avatarUrl: true } } } },
} as const;
