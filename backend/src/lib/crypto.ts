import { createHash, randomBytes, randomInt } from 'node:crypto';

export const sha256 = (value: string) => createHash('sha256').update(value).digest('hex');

export const randomToken = (bytes = 48) => randomBytes(bytes).toString('base64url');

export const randomDigits = (length: number) =>
  Array.from({ length }, () => randomInt(0, 10).toString()).join('');

// Bez znaków łatwych do pomylenia (0/O, 1/I/L).
const INVITE_ALPHABET = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';

export const randomInviteCode = () =>
  Array.from({ length: 8 }, () => INVITE_ALPHABET[randomInt(0, INVITE_ALPHABET.length)]).join('');
