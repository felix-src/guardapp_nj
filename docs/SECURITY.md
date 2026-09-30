# Security

How the Guard Resource App protects unit information, and what still has to happen outside the code before it can hold real soldiers' data.

## Data we hold

| Data | Where | Who can see it |
|---|---|---|
| Name, rank, email, password hash | `user` table | The person; their Readiness NCO and admins (member list) |
| Unit, platoon/squad, duty role | `user`, `org_element` | Unit members, limited by need-to-know (below) |
| Points of contact (duty phone/email) | `point_of_contact` | Logged-in users |
| Command memos (PDF) | `memo` table + `backend/api/uploads/memos/` | Logged-in users |
| Audit log | `audit_log` | Admins |

Out of scope by design (see `PROJECT_SCOPE.md`): classified, operational, medical, or evaluation data; SSNs and DoD ID numbers.

## Controls in place

### Accounts and sign-in
- **Sign-up by unit code only.** Each unit has one code, which rotates weekly and can be replaced immediately. Soldiers can't pick their own role; the server rejects extra fields.
- **Passwords:** at least 12 characters for new passwords; bcrypt (cost 12). Passwords are never logged.
- **Account lockout:** 5 wrong passwords lock the account for 15 minutes, even if the right password is then entered. Every failed login returns the same message whether or not the email exists, and takes the same time.
- **Rate limits per IP:** 120 requests/min overall; login 10/min, sign-up 5/min, code lookup 10/min, password change 5/min.

### Sessions
- **1-hour tokens** (HS256, fixed issuer/audience, algorithm pinned on verify).
- **Remote sign-out:** every token carries the account's `tokenVersion`, checked on every request. "Sign out of all devices" (the user), "Sign out all devices" (their Readiness NCO), `POST /admin/users/:id/revoke-sessions` (admins), and password changes bump it, so stolen tokens stop working immediately.
- **Fresh permissions:** role, unit, and position are loaded from the database on every request (`JwtAuthGuard`), never trusted from the token. Demotions, transfers, and removals apply at once.

### Authorization
- `AdminGuard`: admin-only routes. `UnitScopeGuard`: the unit's Readiness NCO or an admin. `UnitMemberGuard`: members of that unit.
- **Org chart need-to-know** (`org/org-visibility.ts`): leadership (CO, XO, 1SG, PL, PSG, Readiness NCO) sees the whole company. Everyone else sees Company HQ plus their own platoon. Below squad leader, names show as "RANK Last, F.". Data a viewer can't see is never sent to their phone.

### On the phone
- **App lock:** Face ID / Touch ID / passcode when the app opens with a saved session and after 30 seconds in the background. A phone with no passcode can't open the app.
- **App-switcher cover:** the screen is hidden whenever the app isn't in front, so snapshots don't show unit data.
- **Token storage:** iOS Keychain `unlocked_this_device` (not in backups, not moved to a new phone); Android EncryptedSharedPreferences.
- **Nothing cached:** org chart and member data are fetched each time and not saved on the device.

### Server
- **Refuses to start** with missing database settings, a JWT secret under 32 characters or a placeholder, or (in production) missing/non-https CORS origins or join links (`config/env.ts`).
- **Security headers** via Helmet: HSTS, content security policy, no MIME sniffing, no framing.
- **CORS:** production allows only the origins in `CORS_ORIGINS`; development allows only `http://localhost`.
- **Input validation:** every request body is a DTO; unknown fields are rejected.
- **Memo uploads:** admin only, 10 MB cap, must actually be a PDF (checked by content, not name), stored under a random name; downloads can't escape the memo folder.
- **Logs:** one line per request (method, URL, status, time). Unit join codes are masked; bodies and headers are never logged.
- **Audit log:** logins, failed logins, lockouts, sign-ups, password changes, sign-outs, role changes, and every admin/NCO change.
- **Schema changes only through migrations** (`src/database/migrations`); `synchronize` is off.

## Production settings

| Variable | Required | Notes |
|---|---|---|
| `NODE_ENV` | yes | `production` turns on the production checks |
| `JWT_SECRET` | yes | 32+ random characters: `node -e "console.log(require('crypto').randomBytes(48).toString('hex'))"`. Changing it signs everyone out. |
| `DB_HOST`, `DB_PORT`, `DB_USER`, `DB_PASSWORD`, `DB_NAME` | yes | Use a database account with only the rights the app needs, not a superuser |
| `CORS_ORIGINS` | yes | Comma-separated `https://` origins of the sign-up site |
| `JOIN_BASE_URL` | yes | `https://.../join` |
| `TRUST_PROXY` | behind a proxy | e.g. `1`, so rate limits see real client IPs |
| `PORT` | no | Default 3000 |

Serve the API only over HTTPS (TLS terminated at the load balancer or reverse proxy).

## Not covered by the code (needed before real use)

These are organizational or infrastructure steps, not features:

1. **Approval to operate.** Check with the unit's security manager / OPSEC officer and the NJ DMA G6 (IT) before loading real rosters. A DoD system handling PII generally needs an Authority to Operate (ATO) under the Risk Management Framework, a Privacy Impact Assessment, and possibly a System of Records Notice.
2. **Hosting.** Government-approved hosting (e.g. FedRAMP / DoD Impact Level authorized cloud), with encrypted database storage and backups, patching, and monitoring.
3. **Identity.** Many DoD systems require CAC or DoD-approved single sign-on instead of passwords. The session design here (short tokens, server-side revocation) can sit behind such a login later.
4. **Device management.** If units require managed phones (MDM), the app can rely on that in addition to its own lock.
5. **Security testing.** An independent vulnerability scan / penetration test, and dependency scanning (`npm audit`, `flutter pub outdated`) as part of every release.
6. **Incident response.** Who to contact and what to do if a phone is lost or data is exposed: at minimum, use "Sign out all devices", rotate the unit code, and review the audit log.

## Known gaps / next steps
- Two-step login (one-time code) as a second factor.
- Face ID again before opening the org chart.
- Recording who viewed the org chart.
- Memos scoped to units (right now every signed-in user can see every memo).
- Refresh tokens, so sessions can be longer than an hour without weakening revocation.
- Audit log retention and export.
