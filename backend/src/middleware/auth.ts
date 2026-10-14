import type { NextFunction, Request, Response } from 'express';
import { unauthorized } from '../lib/errors.js';
import { verifyAccessToken } from '../lib/tokens.js';

declare global {
  // eslint-disable-next-line @typescript-eslint/no-namespace
  namespace Express {
    interface Request {
      userId?: string;
    }
  }
}

export function requireAuth(req: Request, _res: Response, next: NextFunction) {
  const header = req.headers.authorization;
  if (!header?.startsWith('Bearer ')) throw unauthorized('MISSING_TOKEN');
  req.userId = verifyAccessToken(header.slice(7));
  next();
}

/** Id zalogowanego użytkownika (po `requireAuth`). */
export const uid = (req: Request): string => {
  if (!req.userId) throw unauthorized();
  return req.userId;
};
