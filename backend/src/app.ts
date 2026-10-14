import cors from 'cors';
import express from 'express';
import helmet from 'helmet';
import { pinoHttp } from 'pino-http';
import { config } from './config.js';
import { prisma } from './db.js';
import { logger } from './lib/logger.js';
import { errorHandler } from './middleware/error-handler.js';
import { authRouter } from './routes/auth.js';
import { eventsRouter } from './routes/events.js';
import { groupsRouter } from './routes/groups.js';
import { meRouter } from './routes/me.js';
import { syncRouter } from './routes/sync.js';

export function createApp() {
  const app = express();
  app.set('trust proxy', 1);
  app.use(helmet({ crossOriginResourcePolicy: { policy: 'cross-origin' } }));
  app.use(cors());
  app.use(express.json({ limit: '1mb' }));
  if (!config.isTest) app.use(pinoHttp({ logger, autoLogging: { ignore: (req) => req.url === '/health' } }));

  // Avatary z bazy. Adres zawiera ?v=<znacznik czasu>, więc można je cache'ować długo.
  app.get('/avatars/:userId', async (req, res) => {
    const userId = req.params.userId;
    const avatar = /^[0-9a-f-]{36}$/i.test(userId) ? await prisma.avatar.findUnique({ where: { userId } }) : null;
    if (!avatar) {
      res.status(404).json({ error: { code: 'NOT_FOUND', message: 'Avatar not found' } });
      return;
    }
    res.set({ 'Content-Type': avatar.mimeType, 'Cache-Control': 'public, max-age=604800, immutable' });
    res.send(Buffer.from(avatar.data));
  });
  app.get('/health', (_req, res) => {
    res.json({ ok: true });
  });
  app.use('/auth', authRouter);
  app.use('/me', meRouter);
  app.use('/groups', groupsRouter);
  app.use('/events', eventsRouter);
  app.use('/sync', syncRouter);

  app.use((_req, res) => {
    res.status(404).json({ error: { code: 'NOT_FOUND', message: 'Route not found' } });
  });
  app.use(errorHandler);
  return app;
}
