import type { CodePurpose, User } from '@prisma/client';
import { prisma } from '../db.js';
import { randomDigits, sha256 } from '../lib/crypto.js';
import { badRequest } from '../lib/errors.js';
import { codeMail, sendMail } from '../lib/mailer.js';

const CODE_TTL_MS = 15 * 60_000;
const MAX_ATTEMPTS = 5;

export async function sendCode(user: User, purpose: CodePurpose) {
  const code = randomDigits(6);
  await prisma.$transaction([
    prisma.emailCode.deleteMany({ where: { userId: user.id, purpose } }),
    prisma.emailCode.create({
      data: { userId: user.id, purpose, codeHash: sha256(code), expiresAt: new Date(Date.now() + CODE_TTL_MS) },
    }),
  ]);
  const mail = codeMail(user.language, purpose, code);
  await sendMail(user.email, mail.subject, mail.text);
}

export async function consumeCode(userId: string, purpose: CodePurpose, code: string) {
  const stored = await prisma.emailCode.findFirst({ where: { userId, purpose }, orderBy: { createdAt: 'desc' } });
  if (!stored || stored.expiresAt < new Date()) throw badRequest('CODE_EXPIRED');
  if (stored.attempts >= MAX_ATTEMPTS) throw badRequest('TOO_MANY_ATTEMPTS');
  if (stored.codeHash !== sha256(code.trim())) {
    await prisma.emailCode.update({ where: { id: stored.id }, data: { attempts: { increment: 1 } } });
    throw badRequest('INVALID_CODE');
  }
  await prisma.emailCode.deleteMany({ where: { userId, purpose } });
}
