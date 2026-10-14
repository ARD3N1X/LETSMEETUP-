import rateLimit from 'express-rate-limit';
import { config } from '../config.js';

const limiter = (limit: number, windowMs = 60_000) =>
  rateLimit({
    windowMs,
    limit,
    standardHeaders: 'draft-8',
    legacyHeaders: false,
    skip: () => config.isTest,
    message: { error: { code: 'RATE_LIMITED', message: 'Too many requests, try again later' } },
  });

export const authLimiter = limiter(20);
export const codeLimiter = limiter(10);
