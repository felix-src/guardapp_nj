import { randomInt } from 'crypto';

// No 0/O, 1/I/L — codes get read aloud and retyped.
export const JOIN_CODE_ALPHABET = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
export const JOIN_CODE_LENGTH = 8;
export const JOIN_CODE_TTL_MS = 7 * 24 * 60 * 60 * 1000;

export function generateJoinCode(): string {
  let code = '';
  for (let i = 0; i < JOIN_CODE_LENGTH; i++) {
    code += JOIN_CODE_ALPHABET[randomInt(JOIN_CODE_ALPHABET.length)];
  }
  return code;
}

/** Accepts "k7qm-4xpa", "K7QM 4XPA", etc. and returns the stored form. */
export function normalizeJoinCode(input: string): string {
  return input.toUpperCase().replace(/[^A-Z0-9]/g, '');
}

/** Stored "K7QM4XPA" -> displayed "K7QM-4XPA". */
export function formatJoinCode(code: string): string {
  return `${code.slice(0, 4)}-${code.slice(4)}`;
}
