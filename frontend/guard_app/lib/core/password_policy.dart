/// Mirrors backend auth/password-policy.ts; the server enforces it.
const passwordMinLength = 12;

String? validateNewPassword(String? value) =>
    (value == null || value.length < passwordMinLength)
    ? 'At least $passwordMinLength characters'
    : null;
