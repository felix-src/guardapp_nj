// Account lockout after repeated wrong passwords. Complements the per-IP
// rate limit, which doesn't stop guessing spread across many devices.
export const MAX_FAILED_LOGINS = 5;
export const LOCKOUT_MS = 15 * 60 * 1000;

export interface LockoutState {
  failedLoginCount: number;
  lockedUntil: Date | null;
}

export function isLocked(state: LockoutState, now = new Date()): boolean {
  return state.lockedUntil !== null && state.lockedUntil > now;
}

/** New state after a wrong password; locks on the Nth failure. */
export function afterFailedLogin(
  state: LockoutState,
  now = new Date(),
): LockoutState {
  const count = state.failedLoginCount + 1;
  if (count >= MAX_FAILED_LOGINS) {
    return {
      failedLoginCount: 0,
      lockedUntil: new Date(now.getTime() + LOCKOUT_MS),
    };
  }
  return { failedLoginCount: count, lockedUntil: null };
}
