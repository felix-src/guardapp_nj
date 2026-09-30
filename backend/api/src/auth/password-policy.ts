// Applies to new passwords (sign-up, change password, create-admin), not to
// login, so existing accounts keep working.
export const PASSWORD_MIN_LENGTH = 12;
// bcrypt ignores bytes past 72
export const PASSWORD_MAX_LENGTH = 72;
