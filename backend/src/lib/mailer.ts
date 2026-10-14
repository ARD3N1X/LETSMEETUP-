import nodemailer from 'nodemailer';
import { config } from '../config.js';
import { logger } from './logger.js';

const transport = config.smtp.host
  ? nodemailer.createTransport({
      host: config.smtp.host,
      port: config.smtp.port,
      secure: config.smtp.port === 465,
      auth: config.smtp.user ? { user: config.smtp.user, pass: config.smtp.pass } : undefined,
    })
  : null;

/** Ostatnio wysłane maile — używane wyłącznie w testach. */
export const sentMails: { to: string; subject: string; text: string }[] = [];

export async function sendMail(to: string, subject: string, text: string) {
  if (config.isTest) {
    sentMails.push({ to, subject, text });
    return;
  }
  if (!transport) {
    logger.warn({ to, subject, text }, 'SMTP not configured — e-mail printed to log');
    return;
  }
  try {
    await transport.sendMail({ from: config.smtp.from, to, subject, text });
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
