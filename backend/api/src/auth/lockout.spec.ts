import {
  afterFailedLogin,
  isLocked,
  LOCKOUT_MS,
  MAX_FAILED_LOGINS,
} from './lockout';

describe('account lockout', () => {
  const now = new Date('2026-09-29T12:00:00Z');

  it('counts failures below the limit without locking', () => {
    let state = { failedLoginCount: 0, lockedUntil: null as Date | null };
    for (let i = 1; i < MAX_FAILED_LOGINS; i++) {
      state = afterFailedLogin(state, now);
      expect(state.failedLoginCount).toBe(i);
      expect(isLocked(state, now)).toBe(false);
    }
  });

  it('locks on the last allowed failure, then unlocks after the window', () => {
    const state = afterFailedLogin(
      { failedLoginCount: MAX_FAILED_LOGINS - 1, lockedUntil: null },
      now,
    );
    expect(isLocked(state, now)).toBe(true);
    expect(state.failedLoginCount).toBe(0);
    expect(isLocked(state, new Date(now.getTime() + LOCKOUT_MS + 1))).toBe(
      false,
    );
  });
});
