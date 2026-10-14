import { z } from 'zod';

export const hexColor = z.string().regex(/^#[0-9A-Fa-f]{6}$/, 'Expected #RRGGBB color');
export const isoDate = z.iso.datetime({ offset: true });
export const dateKey = z.string().regex(/^\d{4}-\d{2}-\d{2}$/, 'Expected YYYY-MM-DD');

export const email = z.string().trim().toLowerCase().pipe(z.email());

/** Min. 8 znaków, 1 wielka litera, 1 cyfra (limit 72 wynika z bcrypt). */
export const password = z
  .string()
  .min(8, 'Password must have at least 8 characters')
  .max(72)
  .regex(/[A-ZĄĆĘŁŃÓŚŹŻ]/, 'Password must contain an uppercase letter')
  .regex(/\d/, 'Password must contain a digit');

export const displayName = z.string().trim().min(1).max(50);
