import { createServer } from 'node:http';
import { config } from './config.js';
import { prisma } from './db.js';
import { createApp } from './app.js';
import { logger } from './lib/logger.js';
import { initRealtime } from './realtime/io.js';

const server = createServer(createApp());
initRealtime(server);

server.listen(config.port, () => {
  logger.info(`LET\`SMEETUP API listening on http://localhost:${config.port}`);
});

/** Sprzątanie: stare tombstone'y, wygasłe refresh tokeny i kody. */
async function cleanup() {
  const now = Date.now();
  await prisma.eventTombstone.deleteMany({
    where: { deletedAt: { lt: new Date(now - config.tombstoneRetentionDays * 86_400_000) } },
  });
  await prisma.refreshToken.deleteMany({ where: { expiresAt: { lt: new Date(now) } } });
  await prisma.emailCode.deleteMany({ where: { expiresAt: { lt: new Date(now) } } });
}
setInterval(() => cleanup().catch((err) => logger.error({ err }, 'Cleanup failed')), 6 * 3_600_000).unref();

for (const signal of ['SIGINT', 'SIGTERM'] as const) {
  process.on(signal, () => {
    server.close();
    prisma.$disconnect().finally(() => process.exit(0));
  });
}
