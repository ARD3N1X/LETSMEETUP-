import bcrypt from 'bcryptjs';
import { Router } from 'express';
import { z } from 'zod';
import { config } from '../config.js';
import { prisma } from '../db.js';
import { conflict, forbidden, unauthorized } from '../lib/errors.js';
import { displayName, email, password } from '../lib/schemas.js';
import { serializeMe } from '../lib/serializers.js';
import { issueTokens, revokeRefreshToken, rotateRefreshToken } from '../lib/tokens.js';
import { parse } from '../lib/validate.js';
import { authLimiter, codeLimiter } from '../middleware/rate-limit.js';
import { consumeCode, sendCode } from '../services/codes.js';

export const authRouter = Router();

const language = z.enum(['pl', 'en']).optional();
const code = z.string().trim().min(4).max(10);

async function session(userId: string) {
  const user = await prisma.user.findUniqueOrThrow({ where: { id: userId } });
  return { user: serializeMe(user), ...(await issueTokens(userId)) };
}

authRouter.post('/register', authLimiter, async (req, res) => {
  const body = parse(z.object({ email, password, displayName, language }), req.body);
  const passwordHash = await bcrypt.hash(body.password, 12);
  const verifiedNow = config.requireEmailVerification ? null : new Date();

  const existing = await prisma.user.findUnique({ where: { email: body.email } });
  if (existing?.emailVerifiedAt) throw conflict('EMAIL_TAKEN', 'An account with this e-mail already exists');

  // Niezweryfikowane konto można zarejestrować ponownie (np. gdy kod nie dotarł).
  const user = existing
    ? await prisma.user.update({
        where: { id: existing.id },
        data: { passwordHash, displayName: body.displayName, emailVerifiedAt: verifiedNow },
      })
    : await prisma.user.create({
        data: {
          email: body.email,
          passwordHash,
          displayName: body.displayName,
          language: body.language ?? 'pl',
          emailVerifiedAt: verifiedNow,
        },
      });

  if (!config.requireEmailVerification) {
    res.status(201).json({ needsVerification: false, ...(await session(user.id)) });
    return;
  }
  await sendCode(user, 'verify_email');
  res.status(201).json({ needsVerification: true });
});

authRouter.post('/verify-email', codeLimiter, async (req, res) => {
  const body = parse(z.object({ email, code }), req.body);
  const user = await prisma.user.findUnique({ where: { email: body.email } });
  if (!user) throw unauthorized('INVALID_CODE');
  if (!user.emailVerifiedAt) {
    await consumeCode(user.id, 'verify_email', body.code);
    await prisma.user.update({ where: { id: user.id }, data: { emailVerifiedAt: new Date() } });
  }
  res.json(await session(user.id));
});

authRouter.post('/resend-verification', codeLimiter, async (req, res) => {
  const body = parse(z.object({ email }), req.body);
  const user = await prisma.user.findUnique({ where: { email: body.email } });
  if (user && !user.emailVerifiedAt) await sendCode(user, 'verify_email');
  res.json({ ok: true });
});

authRouter.post('/login', authLimiter, async (req, res) => {
  const body = parse(z.object({ email, password: z.string().min(1).max(200) }), req.body);
  const user = await prisma.user.findUnique({ where: { email: body.email } });
  const valid = user ? await bcrypt.compare(body.password, user.passwordHash) : false;
  if (!user || !valid) throw unauthorized('INVALID_CREDENTIALS', 'Invalid e-mail or password');
  if (!user.emailVerifiedAt) throw forbidden('EMAIL_NOT_VERIFIED', 'E-mail address is not verified');
  res.json(await session(user.id));
});

authRouter.post('/refresh', authLimiter, async (req, res) => {
  const body = parse(z.object({ refreshToken: z.string().min(10) }), req.body);
  const { accessToken, refreshToken } = await rotateRefreshToken(body.refreshToken);
  res.json({ accessToken, refreshToken });
});

authRouter.post('/logout', async (req, res) => {
  const body = parse(z.object({ refreshToken: z.string().min(10) }), req.body);
  await revokeRefreshToken(body.refreshToken);
  res.json({ ok: true });
});

authRouter.post('/forgot-password', codeLimiter, async (req, res) => {
  const body = parse(z.object({ email }), req.body);
  const user = await prisma.user.findUnique({ where: { email: body.email } });
  if (user) await sendCode(user, 'reset_password');
  // Zawsze ta sama odpowiedź — nie zdradzamy, czy konto istnieje.
  res.json({ ok: true });
});

authRouter.post('/reset-password', codeLimiter, async (req, res) => {
  const body = parse(z.object({ email, code, newPassword: password }), req.body);
  const user = await prisma.user.findUnique({ where: { email: body.email } });
  if (!user) throw unauthorized('INVALID_CODE');
  await consumeCode(user.id, 'reset_password', body.code);
  await prisma.$transaction([
    prisma.user.update({
      where: { id: user.id },
      // Kod z maila potwierdza też adres e-mail.
      data: {
        passwordHash: await bcrypt.hash(body.newPassword, 12),
        emailVerifiedAt: user.emailVerifiedAt ?? new Date(),
      },
    }),
    prisma.refreshToken.updateMany({ where: { userId: user.id, revokedAt: null }, data: { revokedAt: new Date() } }),
  ]);
  res.json(await session(user.id));
});
