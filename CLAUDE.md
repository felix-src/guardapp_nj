# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Guard Resource App: a read-only resource hub for National Guard soldiers (unit resources, command memo PDFs, unit POCs, soldier/admin roles). Scope rules from [docs/PROJECT_SCOPE.md](docs/PROJECT_SCOPE.md) — do not add features that handle classified/operational/medical data, evaluations, messaging/chat, soldier tracking, discipline/counseling, or sensitive PII.

**Note:** [docs/readme.md](docs/readme.md) describes an Express/MongoDB backend on port 5000. That is outdated — the real backend is **NestJS + TypeORM + PostgreSQL on port 3000**. Trust the code.

## Layout

- `backend/api/` — NestJS 11 API (TypeScript)
- `frontend/guard_app/` — Flutter app (Dart SDK ^3.10), targets Android emulator and web

## Commands

Backend (run from `backend/api/`):
```
npm install
npm run start:dev          # watch mode, listens on :3000
npm run build
npm run lint               # eslint --fix
npm run format             # prettier
npm test                   # unit tests (src/**/*.spec.ts)
npx jest src/app.controller.spec.ts   # single test file
npx jest -t "test name"               # single test by name
npm run test:e2e           # test/*.e2e-spec.ts — boots full AppModule, needs a live Postgres
npm run create-admin -- <email>   # create or promote an admin (prompts for password, or ADMIN_PASSWORD env)
npm run seed:demo          # add '(Sample)' units/contacts + a sample memo; `-- --remove` deletes them
```

There is no in-app registration or admin UI yet: the first admin comes from `create-admin`, and units/contacts/memos are added via the admin API routes. `start:dev` on Windows sometimes crashes after rapid file changes ("process not found" / `EADDRINUSE`) — just restart it.

Frontend (run from `frontend/guard_app/`):
```
flutter pub get
flutter run                # pick emulator/device; -d chrome for web
flutter run --dart-define=API_BASE_URL=http://<pc-lan-ip>:3000   # physical phone
flutter analyze
flutter test
flutter test test/widget_test.dart
```

## Backend architecture

- **Single module.** Everything is registered directly in [src/app.module.ts](backend/api/src/app.module.ts) — no feature modules. New entities must be added to both the `entities` array in `TypeOrmModule.forRoot` and `TypeOrmModule.forFeature`; new controllers/providers go in the same module.
- **Validation:** a global `ValidationPipe` (`whitelist`, `forbidNonWhitelisted`, `transform`) is set in `main.ts`. Request bodies must be class-validator DTOs (see `auth/dto/`, `units/dto/`); unknown fields are rejected with 400. Inline object types (`@Body() body: {...}`) skip validation — don't use them. Use `ParseIntPipe` for numeric route params.
- **Units & points of contact:** `Unit` 1→many `PointOfContact` (cascade delete). All `/units` routes require login; `GET /units/:id` returns the unit with `contacts`. Admin-only: `POST /units`, `POST /units/:id/contacts`, `DELETE /units/:id/contacts/:contactId`. POCs hold official duty contact info only (position, duty phone, .mil email).
- **Config via `.env`** (loaded by `dotenv` at the top of `main.ts`): `DB_HOST`, `DB_PORT`, `DB_USER`, `DB_PASSWORD`, `DB_NAME`, `JWT_SECRET`. Port 3000 is hardcoded in `main.ts`.
- **Schema:** `synchronize: true` — TypeORM auto-alters tables from entity definitions; there are no migrations.
- **Auth flow:** `POST /auth/login` returns `{ access_token }`, a JWT (1h expiry) with payload `{ sub: userId, role }`. Passwords hashed with bcrypt. New users default to `Role.Soldier`; admins are made via `PATCH /admin/users/:id/promote`.
- **Guards:** protect routes with `@UseGuards(JwtAuthGuard, AdminGuard)`. `JwtAuthGuard` (custom, not Passport despite the dependency) verifies the Bearer token and sets `req.user = { sub, role }`; `AdminGuard` then checks `req.user.role === 'admin'`. Order matters. Never trust client-sent role data; role comes only from the verified JWT.
- **Audit logging convention:** every admin mutation calls `auditService.log(req.user.sub, req.user.role, 'ACTION_NAME', '/endpoint')` after succeeding. `GET /audit` (admin) returns the latest 50 entries. Follow this pattern for new admin actions.
- **Memos:** admin uploads a PDF via multipart `POST /memos` (field `file`, plus `title`); multer stores it at `uploads/memos/memo-<timestamp>.pdf` (relative to the process cwd, so run the server from `backend/api/`). Listing and downloading require `JwtAuthGuard`.
- `LoggerMiddleware` logs every request, but it runs before guards so `req.user` is always unset there.

## Frontend architecture

- Feature-folder layout: `lib/core/` (API base URL, auth API, secure token storage) and `lib/features/<feature>/`.
- **API base URL** ([lib/core/config.dart](frontend/guard_app/lib/core/config.dart)): `API_BASE_URL` dart-define if given, else `localhost:3000` on web, else `10.0.2.2:3000` (Android emulator → host).
- JWT is persisted with `flutter_secure_storage` (`TokenStorage`). `main.dart` reads it at startup and picks the initial route (`/` login vs `/home`). Authenticated requests go through `authedGet` in [lib/core/authed_http.dart](frontend/guard_app/lib/core/authed_http.dart), which attaches the token and, on 401 or missing token, clears it and resets to the login route via the global `navigatorKey` (set on `MaterialApp`). Screens must check `mounted` after awaiting API calls.
- Plain `http` + `Navigator` named routes; no state-management library is in use yet (despite docs mentioning Provider).
- Memo download writes the PDF to the temp dir (`path_provider`) and opens it with `open_filex` — mobile-only; won't work on web.

## Android build

The Gradle wrapper is 9.3.1 (AGP 8.11.1, Kotlin 2.2.20) because current Android Studio ships Java 25, which Gradle 8.x can't run on. The emulator requires a Windows hypervisor (Windows Hypervisor Platform) to be enabled.
