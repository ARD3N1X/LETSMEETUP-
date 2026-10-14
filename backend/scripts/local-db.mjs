// Lokalny PostgreSQL bez Dockera (embedded-postgres). Użycie: node scripts/local-db.mjs [port] [katalog]
import EmbeddedPostgres from 'embedded-postgres';
import { existsSync } from 'node:fs';

const port = Number(process.argv[2] ?? 5432);
const dir = process.argv[3] ?? './.pgdata';
const pg = new EmbeddedPostgres({ databaseDir: dir, user: 'letsmeetup', password: 'letsmeetup', port, persistent: true,
  initdbFlags: ['--encoding=UTF8', '--locale=C'] });

const fresh = !existsSync(dir);
if (fresh) await pg.initialise();
await pg.start();
if (fresh) await pg.createDatabase('letsmeetup');
console.log(`PostgreSQL ready on port ${port} (data: ${dir}). Ctrl+C to stop.`);

const stop = async () => { await pg.stop(); process.exit(0); };
process.on('SIGINT', stop);
process.on('SIGTERM', stop);
