import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    globalSetup: './tests/global-setup.ts',
    env: {
      NODE_ENV: 'test',
      JWT_SECRET: 'test-secret-test-secret-test-secret',
      REQUIRE_EMAIL_VERIFICATION: 'true',
      DATABASE_URL:
        process.env.TEST_DATABASE_URL ??
        'postgresql://letsmeetup:letsmeetup@localhost:5432/letsmeetup_test?schema=public',
      MAX_GROUPS_PER_USER: '20',
      MAX_GROUP_MEMBERS: '3',
    },
    fileParallelism: false,
    hookTimeout: 120_000,
    testTimeout: 30_000,
  },
});
