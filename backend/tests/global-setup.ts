import { execSync } from 'node:child_process';

export default function setup() {
  const url =
    process.env.TEST_DATABASE_URL ?? 'postgresql://letsmeetup:letsmeetup@localhost:5432/letsmeetup_test?schema=public';
  // Stosuje brakujące migracje na bazie testowej (dane czyści każdy plik testów).
  execSync('npx prisma migrate deploy', {
    env: { ...process.env, DATABASE_URL: url },
    stdio: 'inherit',
  });
}
