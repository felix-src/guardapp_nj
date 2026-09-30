import type { Request } from 'express';
import { Role } from './roles.enum';

/** What a signed token carries. `ver` must match User.tokenVersion. */
export interface JwtPayload {
  sub: number;
  ver: number;
}

/**
 * The signed-in user, loaded fresh from the database on every request by
 * JwtAuthGuard. Guards and controllers use this, never claims from the
 * token itself, so demotions, transfers, and sign-outs apply immediately.
 */
export interface AuthUser {
  id: number;
  role: Role;
  unitId: number | null;
  orgElementId: number | null;
  dutyRole: string | null;
}

export interface AuthedRequest extends Request {
  user?: AuthUser;
}
