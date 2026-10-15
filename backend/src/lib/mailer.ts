import nodemailer from 'nodemailer';
import { config } from '../config.js';
import { logger } from './logger.js';

const transport = config.smtp.host
  ? nodemailer.createTransport({
      host: config.smtp.host,
      port: config.smtp.port,
      secure: config.smtp.port === 465,
      auth: config.smtp.user ? { user: config.smtp.user, pass: config.smtp.pass } : undefined,
      // Bez limitów nodemailer czeka ~2 min, gdy hosting blokuje porty SMTP.
      connectionTimeout: 10_000,
      greetingTimeout: 10_000,
      socketTimeout: 20_000,
    })
  : null;

/** "Nazwa <adres@x.pl>" → { name, email } (format nadawcy w API Brevo). */
function parseSender(from: string) {
  const match = from.match(/^\s*"?([^"<]*?)"?\s*<([^>]+)>\s*$/);
  return match ? { name: match[1]!.trim() || undefined, email: match[2]!.trim() } : { email: from.trim() };
}

/**
 * Wysyłka przez API HTTP Brevo (port 443). Używana, gdy ustawiono BREVO_API_KEY —
 * np. na Render Free, który blokuje wychodzące połączenia SMTP.
 */
async function sendViaBrevoApi(to: string, subject: string, text: string) {
  const res = await fetch('https://api.brevo.com/v3/smtp/email', {
    method: 'POST',
    headers: { 'api-key': config.brevoApiKey, 'content-type': 'application/json', accept: 'application/json' },
    body: JSON.stringify({ sender: parseSender(config.smtp.from), to: [{ email: to }], subject, textContent: text }),
    signal: AbortSignal.timeout(15_000),
  });
  if (!res.ok) throw new Error(`Brevo API ${res.status}: ${await res.text()}`);
}

/** Ostatnio wysłane maile — używane wyłącznie w testach. */
export const sentMails: { to: string; subject: string; text: string }[] = [];

export async function sendMail(to: string, subject: string, text: string) {
  if (config.isTest) {
    sentMails.push({ to, subject, text });
    return;
  }
  if (!config.brevoApiKey && !transport) {
    logger.warn({ to, subject, text }, 'E-mail not configured — e-mail printed to log');
    return;
  }
  try {
    if (config.brevoApiKey) await sendViaBrevoApi(to, subject, text);
    else await transport!.sendMail({ from: config.smtp.from, to, subject, text });
    logger.info({ to, subject }, 'E-mail sent');
  } catch (err) {
    logger.error({ err, to }, 'Sending e-mail failed');
  }
}

export function codeMail(language: string, purpose: 'verify_email' | 'reset_password', code: string) {
  const en = language === 'en';
  if (purpose === 'verify_email') {
    return {
      subject: en ? 'LET`SMEETUP — confirm your e-mail' : 'LET`SMEETUP — potwierdź adres e-mail',
      text: en
        ? `Your verification code: ${code}\n\nThe code is valid for 15 minutes.`
        : `Twój kod weryfikacyjny: ${code}\n\nKod jest ważny przez 15 minut.`,
    };
  }
  return {
    subject: en ? 'LET`SMEETUP — password reset' : 'LET`SMEETUP — reset hasła',
    text: en
      ? `Your password reset code: ${code}\n\nIf you did not request it, ignore this e-mail.`
      : `Twój kod do zmiany hasła: ${code}\n\nJeśli to nie Ty, zignoruj tę wiadomość.`,
  };
}
