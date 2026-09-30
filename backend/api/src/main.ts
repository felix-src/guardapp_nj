import * as dotenv from 'dotenv';
dotenv.config({ quiet: true });

import { ValidationPipe } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import type { NestExpressApplication } from '@nestjs/platform-express';
import helmet from 'helmet';
import { AppModule } from './app.module';
import { corsOrigins, validateEnv } from './config/env';

async function bootstrap() {
  // Refuse to start insecurely (missing DB settings, weak JWT secret, open
  // CORS in production). See config/env.ts.
  const problems = validateEnv();
  if (problems.length > 0) {
    console.error(
      'Refusing to start:\n' + problems.map((p) => `  - ${p}`).join('\n'),
    );
    process.exit(1);
  }

  const app = await NestFactory.create<NestExpressApplication>(AppModule);

  // Security headers: HSTS, no sniffing, no framing, strict referrer, etc.
  app.use(helmet());

  // Behind a load balancer/reverse proxy, set TRUST_PROXY (e.g. "1") so rate
  // limits see the real client IP instead of the proxy's.
  if (process.env.TRUST_PROXY) {
    app.set('trust proxy', process.env.TRUST_PROXY);
  }

  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
    }),
  );

  // Only the web sign-up page is a browser client; the app uses Bearer
  // tokens, not cookies, so credentials stay off.
  app.enableCors({ origin: corsOrigins(), credentials: false });

  await app.listen(Number(process.env.PORT ?? 3000));
}

void bootstrap();
