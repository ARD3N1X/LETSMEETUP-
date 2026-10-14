import jwt from 'jsonwebtoken';
import { config } from '../config.js';
import { prisma } from '../db.js';
import { randomToken, sha256 } from './crypto.js';
import { unauthorized } from './errors.js';

interface AccessPayload {
  sub: string;
  typ: 'access';
}

export function signAccessToken(userId: string): string {
  const payload: AccessPayload = { sub: userId, typ: 'access' };
  return jwt.sign(payload, config.jwtSecret, { expiresIn: `${config.accessTokenTtlMin}m` });
}

export function verifyAccessToken(token: string): string {
  try {
    const payload = jwt.verify(token, config.jwtSecret) as Partial<AccessPayload>;
    if (payload.typ !== 'access' || typeof payload.sub !== 'string') throw new Error('bad token');
    return payload.sub;
  } catch {
    throw unauthorized('INVALID_TOKEN');
  }
}

export async function issueTokens(userId: string) {
  const refreshToken = randomToken();
  await prisma.refreshToken.create({
    data: {
      userId,
      tokenHash: sha256(refreshToken),
      expiresAt: new Date(Date.now() + config.refreshTokenTtlDays * 86_400_000),
    },
  });
  return { accessToken: signAccessToken(userId), refreshToken };
}

/** Rotacja: stary refresh token zostaje unieważniony. Ponowne użycie unieważnionego = wylogowanie wszystkich sesji. */
export async function rotateRefreshToken(refreshToken: string) {
  const stored = await prisma.refreshToken.findUnique({ where: { tokenHash: sha256(refreshToken) } });
  if (!stored) throw unauthorized('INVALID_REFRESH_TOKEN');
  if (stored.revokedAt) {
    await prisma.refreshToken.updateMany({
      where: { userId: stored.userId, revokedAt: null },
      data: { revokedAt: new Date() },
    });
    throw unauthorized('REFRESH_TOKEN_REUSED');
  }
  if (stored.expiresAt < new Date()) throw unauthorized('REFRESH_TOKEN_EXPIRED');
  await prisma.refreshToken.update({ where: { id: stored.id }, data: { revokedAt: new Date() } });
  return { userId: stored.userId, ...(await issueTokens(stored.userId)) };
}

export async function revokeRefreshToken(refreshToken: string) {
  await prisma.refreshToken.updateMany({
    where: { tokenHash: sha256(refreshToken), revokedAt: null },
    data: { revokedAt: new Date() },
  });
}
