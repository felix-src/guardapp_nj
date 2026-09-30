// Startup configuration checks. The server refuses to start with missing or
// weak settings rather than running insecurely.

const REQUIRED = ['DB_HOST', 'DB_PORT', 'DB_USER', 'DB_PASSWORD', 'DB_NAME'];
const PLACEHOLDER_SECRETS = [
  'your_secret_key_here',
  'changeme',
  'secret',
  'jwtsecret',
];
const MIN_SECRET_LENGTH = 32;

export function isProduction(env: NodeJS.ProcessEnv = process.env): boolean {
  return env.NODE_ENV === 'production';
}

/** Problems with the environment; empty when it's safe to start. */
export function validateEnv(env: NodeJS.ProcessEnv = process.env): string[] {
  const errors: string[] = [];

  for (const key of REQUIRED) {
    if (!env[key]) errors.push(`${key} is not set`);
  }

  const secret = env.JWT_SECRET ?? '';
  if (secret.length < MIN_SECRET_LENGTH) {
    errors.push(
      `JWT_SECRET must be at least ${MIN_SECRET_LENGTH} random characters ` +
        `(generate one with: node -e "console.log(require('crypto').randomBytes(48).toString('hex'))")`,
    );
  } else if (PLACEHOLDER_SECRETS.includes(secret.toLowerCase())) {
    errors.push('JWT_SECRET is a placeholder value');
  }

  if (isProduction(env)) {
    const origins = parseOrigins(env.CORS_ORIGINS);
    if (origins.length === 0) {
      errors.push('CORS_ORIGINS must list the allowed web origins');
    }
    for (const origin of origins) {
      if (!origin.startsWith('https://')) {
        errors.push(`CORS origin must use https: ${origin}`);
      }
    }
    if (!env.JOIN_BASE_URL?.startsWith('https://')) {
      errors.push('JOIN_BASE_URL must be an https:// URL in production');
    }
  }

  return errors;
}

function parseOrigins(value: string | undefined): string[] {
  return (value ?? '')
    .split(',')
    .map((o) => o.trim())
    .filter(Boolean);
}

/**
 * Which browser origins may call the API. The mobile app doesn't use CORS;
 * this only concerns the web sign-up page. Production: exactly the listed
 * origins. Development: any http://localhost port.
 */
export function corsOrigins(
  env: NodeJS.ProcessEnv = process.env,
): string[] | RegExp {
  return isProduction(env)
    ? parseOrigins(env.CORS_ORIGINS)
    : /^http:\/\/localhost(:\d+)?$/;
}
