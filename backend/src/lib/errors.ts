export class HttpError extends Error {
  constructor(
    public status: number,
    public code: string,
    message?: string,
    public details?: unknown,
  ) {
    super(message ?? code);
  }
}

export const badRequest = (code: string, message?: string, details?: unknown) =>
  new HttpError(400, code, message, details);
export const unauthorized = (code = 'UNAUTHORIZED', message?: string) => new HttpError(401, code, message);
export const forbidden = (code = 'FORBIDDEN', message?: string) => new HttpError(403, code, message);
export const notFound = (code = 'NOT_FOUND', message?: string) => new HttpError(404, code, message);
export const conflict = (code: string, message?: string) => new HttpError(409, code, message);
