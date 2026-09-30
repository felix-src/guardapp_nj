import { Injectable, NestMiddleware } from '@nestjs/common';
import type { Request, Response, NextFunction } from 'express';

/** Removes secrets that appear in URLs (unit join codes) before logging. */
export function redactUrl(url: string): string {
  return url
    .replace(/(\/auth\/join\/)[^/?#]+/i, '$1***')
    .replace(/([?&]code=)[^&#]+/i, '$1***');
}

/**
 * One line per request: method, redacted URL, status, duration. Never logs
 * bodies or headers (passwords, tokens). Written when the response finishes.
 */
@Injectable()
export class LoggerMiddleware implements NestMiddleware {
  use(req: Request, res: Response, next: NextFunction) {
    const started = Date.now();
    res.on('finish', () => {
      console.log(
        `[${new Date().toISOString()}] ${req.method} ${redactUrl(req.originalUrl)} ${res.statusCode} ${Date.now() - started}ms`,
      );
    });
    next();
  }
}
