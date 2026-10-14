import { readFileSync } from 'node:fs';
import { config } from '../config.js';
import { prisma } from '../db.js';
import { logger } from './logger.js';

type Messaging = import('firebase-admin/messaging').Messaging;

let messagingPromise: Promise<Messaging | null> | null = null;

function getMessaging(): Promise<Messaging | null> {
  if (!messagingPromise) {
    messagingPromise = (async () => {
      if (!config.firebaseServiceAccountFile || config.isTest) return null;
      try {
        const { initializeApp, cert } = await import('firebase-admin/app');
        const { getMessaging: gm } = await import('firebase-admin/messaging');
        const account = JSON.parse(readFileSync(config.firebaseServiceAccountFile, 'utf8'));
        const app = initializeApp({ credential: cert(account) });
        logger.info('FCM push enabled');
        return gm(app);
      } catch (err) {
        logger.error({ err }, 'FCM initialisation failed — push disabled');
        return null;
      }
    })();
  }
  return messagingPromise;
}

export interface PushMessage {
  title: string;
  body: string;
  data: Record<string, string>;
}

/** Wysyła push do urządzeń wskazanych użytkowników (paczki po 500 tokenów — limit FCM). */
export async function sendPush(userIds: string[], buildMessage: (language: string) => PushMessage) {
  if (userIds.length === 0) return;
  const messaging = await getMessaging();
  if (!messaging) return;

  const devices = await prisma.deviceToken.findMany({
    where: { userId: { in: userIds }, user: { pushEnabled: true } },
    include: { user: { select: { language: true } } },
  });

  const byLanguage = new Map<string, string[]>();
  for (const d of devices) {
    const list = byLanguage.get(d.user.language) ?? [];
    list.push(d.token);
    byLanguage.set(d.user.language, list);
  }

  for (const [language, tokens] of byLanguage) {
    const msg = buildMessage(language);
    for (let i = 0; i < tokens.length; i += 500) {
      const batch = tokens.slice(i, i + 500);
      try {
        const res = await messaging.sendEachForMulticast({
          tokens: batch,
          notification: { title: msg.title, body: msg.body },
          data: msg.data,
        });
        const invalid = res.responses
          .map((r, idx) => (!r.success && isInvalidTokenError(r.error?.code) ? batch[idx] : null))
          .filter((t): t is string => t !== null);
        if (invalid.length) await prisma.deviceToken.deleteMany({ where: { token: { in: invalid } } });
      } catch (err) {
        logger.error({ err }, 'FCM send failed');
      }
    }
  }
}

function isInvalidTokenError(code?: string) {
  return (
    code === 'messaging/registration-token-not-registered' ||
    code === 'messaging/invalid-registration-token' ||
    code === 'messaging/invalid-argument'
  );
}
