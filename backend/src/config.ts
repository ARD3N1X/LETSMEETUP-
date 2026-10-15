import 'dotenv/config';

function num(name: string, fallback: number): number {
  const raw = process.env[name];
  if (raw === undefined || raw === '') return fallback;
  const value = Number(raw);
  if (Number.isNaN(value)) throw new Error(`Env ${name} must be a number`);
  return value;
}

const jwtSecret = process.env.JWT_SECRET ?? '';
if (jwtSecret.length < 16) {
  throw new Error('JWT_SECRET must be set (min. 16 characters)');
}

export const config = {
  port: num('PORT', 3000),
  // Render ustawia RENDER_EXTERNAL_URL automatycznie.
  publicUrl: (process.env.PUBLIC_URL || process.env.RENDER_EXTERNAL_URL || '').replace(/\/$/, ''),
  isTest: process.env.NODE_ENV === 'test',
  jwtSecret,
  accessTokenTtlMin: num('ACCESS_TOKEN_TTL_MIN', 15),
  refreshTokenTtlDays: num('REFRESH_TOKEN_TTL_DAYS', 30),
  smtp: {
    host: process.env.SMTP_HOST ?? '',
    port: num('SMTP_PORT', 587),
    user: process.env.SMTP_USER ?? '',
    pass: process.env.SMTP_PASS ?? '',
    from: process.env.SMTP_FROM ?? 'LET`SMEETUP <no-reply@letsmeetup.local>',
  },
  /** Klucz API Brevo (wysyłka przez HTTPS zamiast SMTP). */
  brevoApiKey: process.env.BREVO_API_KEY ?? '',
  requireEmailVerification: (process.env.REQUIRE_EMAIL_VERIFICATION ?? 'true') !== 'false',
  firebaseServiceAccountFile: process.env.FIREBASE_SERVICE_ACCOUNT_FILE ?? '',
  maxGroupMembers: num('MAX_GROUP_MEMBERS', 100),
  maxGroupsPerUser: num('MAX_GROUPS_PER_USER', 20),
  /** Po tylu dniach tombstone'y są usuwane; starszy kursor sync wymusza pełną synchronizację. */
  tombstoneRetentionDays: 60,
};
