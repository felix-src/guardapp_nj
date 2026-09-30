import { corsOrigins, validateEnv } from './env';

const base = {
  DB_HOST: 'localhost',
  DB_PORT: '5432',
  DB_USER: 'u',
  DB_PASSWORD: 'p',
  DB_NAME: 'db',
  JWT_SECRET: 'a'.repeat(64),
};

describe('validateEnv', () => {
  it('accepts a complete development config', () => {
    expect(validateEnv(base)).toEqual([]);
  });

  it('rejects missing database settings and short or placeholder secrets', () => {
    expect(validateEnv({ ...base, DB_HOST: '' })).toEqual([
      'DB_HOST is not set',
    ]);
    expect(validateEnv({ ...base, JWT_SECRET: 'short' })[0]).toMatch(
      /at least 32/,
    );
    expect(validateEnv({ ...base, JWT_SECRET: undefined })[0]).toMatch(
      /at least 32/,
    );
  });

  it('requires https CORS origins and join links in production', () => {
    const prod = { ...base, NODE_ENV: 'production' };
    expect(validateEnv(prod)).toEqual(
      expect.arrayContaining([
        'CORS_ORIGINS must list the allowed web origins',
        'JOIN_BASE_URL must be an https:// URL in production',
      ]),
    );
    expect(
      validateEnv({
        ...prod,
        CORS_ORIGINS: 'http://join.example.mil',
        JOIN_BASE_URL: 'https://join.example.mil/join',
      }),
    ).toEqual(['CORS origin must use https: http://join.example.mil']);
    expect(
      validateEnv({
        ...prod,
        CORS_ORIGINS: 'https://join.example.mil',
        JOIN_BASE_URL: 'https://join.example.mil/join',
      }),
    ).toEqual([]);
  });
});

describe('corsOrigins', () => {
  it('allows only localhost in development', () => {
    const origins = corsOrigins(base) as RegExp;
    expect(origins.test('http://localhost:8080')).toBe(true);
    expect(origins.test('http://localhost')).toBe(true);
    expect(origins.test('http://evil.example')).toBe(false);
    expect(origins.test('http://localhost.evil.example')).toBe(false);
  });

  it('allows exactly the listed origins in production', () => {
    expect(
      corsOrigins({
        ...base,
        NODE_ENV: 'production',
        CORS_ORIGINS: 'https://a.example, https://b.example',
      }),
    ).toEqual(['https://a.example', 'https://b.example']);
  });
});
