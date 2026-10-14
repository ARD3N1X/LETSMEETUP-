import type { Server as HttpServer } from 'node:http';
import { Server } from 'socket.io';
import { prisma } from '../db.js';
import { logger } from '../lib/logger.js';
import { verifyAccessToken } from '../lib/tokens.js';

let io: Server | null = null;

const userRoom = (userId: string) => `user:${userId}`;
const groupRoom = (groupId: string) => `group:${groupId}`;

export function initRealtime(server: HttpServer) {
  io = new Server(server, { cors: { origin: '*' } });

  io.use((socket, next) => {
    try {
      const token = (socket.handshake.auth as { token?: string })?.token;
      if (!token) return next(new Error('MISSING_TOKEN'));
      socket.data.userId = verifyAccessToken(token);
      next();
    } catch {
      next(new Error('INVALID_TOKEN'));
    }
  });

  io.on('connection', async (socket) => {
    const userId = socket.data.userId as string;
    const memberships = await prisma.groupMember.findMany({ where: { userId }, select: { groupId: true } });
    await socket.join([userRoom(userId), ...memberships.map((m) => groupRoom(m.groupId))]);
    socket.emit('ready');
    logger.debug({ userId }, 'socket connected');
  });

  return io;
}

/**
 * Zdarzenia wysyłane do klientów:
 * - `event:upsert`  { event, actorId }
 * - `event:delete`  { id, groupId, actorId }
 * - `groups:changed` {}            — klient pobiera listę grup ponownie (sync)
 * - `group:removed` { groupId }    — użytkownik stracił dostęp do grupy
 */
export const realtime = {
  toUser(userId: string, event: string, payload: unknown = {}) {
    io?.to(userRoom(userId)).emit(event, payload);
  },
  toGroup(groupId: string, event: string, payload: unknown = {}) {
    io?.to(groupRoom(groupId)).emit(event, payload);
  },
  /** Wydarzenie grupowe → pokój grupy, prywatne → pokój autora. */
  toEventAudience(groupId: string | null, ownerId: string, event: string, payload: unknown) {
    if (groupId) this.toGroup(groupId, event, payload);
    else this.toUser(ownerId, event, payload);
  },
  joinGroup(userId: string, groupId: string) {
    io?.in(userRoom(userId)).socketsJoin(groupRoom(groupId));
  },
  leaveGroup(userId: string, groupId: string) {
    io?.in(userRoom(userId)).socketsLeave(groupRoom(groupId));
  },
  closeGroup(groupId: string) {
    io?.in(groupRoom(groupId)).socketsLeave(groupRoom(groupId));
  },
};
