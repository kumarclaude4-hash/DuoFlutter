# DuoShield

DuoShield is an end-to-end encrypted messaging Android app with Signal protocol, WebRTC calls, and Firebase backend — served by a TypeScript/Express push server running on Replit.

## Run & Operate

- `pnpm --filter @workspace/api-server run dev` — run the API/push server (port assigned by workflow)
- `pnpm run typecheck` — full typecheck across all packages
- `pnpm run build` — typecheck + build all packages
- `pnpm --filter @workspace/api-spec run codegen` — regenerate API hooks and Zod schemas from the OpenAPI spec
- `node scripts/firebase-setup.mjs` — (re)generate `google-services.json` + `firebase_options.dart` from `GOOGLE_APPLICATION_CREDENTIALS_JSON`

## Stack

- pnpm workspaces, Node.js 24, TypeScript 5.9
- API/Push server: Express 5 + Firebase Admin SDK v14 + Helmet + express-rate-limit
- Flutter app: Dart/Flutter 3.32, Android only (minSdk 26)
- DB (Flutter): SQLCipher via sqflite_sqlcipher (AES-256-CBC encrypted)
- Signal E2E: libsignal_protocol_dart
- WebRTC: flutter_webrtc + Cloudflare TURN
- Media storage: Backblaze B2 (AES-256-GCM encrypted before upload)
- Firebase: Auth (custom tokens), Firestore, FCM

## Where things live

- `artifacts/api-server/` — TypeScript Express push server (all DuoShield API routes + health)
- `duoshield_app/` — Flutter Android app source
- `duoshield_server/` — Original JavaScript push server (reference; not used in production here)
- `firebase.json`, `firestore.rules`, `firestore.indexes.json` — Firebase CLI config
- `scripts/firebase-setup.mjs` — Auto-generates `google-services.json` + `firebase_options.dart`
- `lib/api-spec/openapi.yaml` — OpenAPI source of truth for generated hooks

## API Routes (all under `/api/`)

| Route | Auth | Description |
|---|---|---|
| `GET /api/healthz` | none | Health check |
| `POST /api/mintToken` | shared secret | Mint Firebase custom token for new/existing user |
| `POST /api/createChat` | Firebase token | Create deterministic chat doc in Firestore |
| `POST /api/migrateUid` | Firebase token | Migrate identity from oldUid → newUid |
| `POST /api/removeGroupMember` | Firebase token | Remove member from group (admin only) |
| `POST /api/turnCredentials` | Firebase token | Generate Cloudflare TURN credentials |
| `POST /api/b2PresignedPut` | Firebase token | Presigned PUT URL for B2 upload |
| `POST /api/b2PresignedGet` | Firebase token | Presigned GET URL for B2 download |
| `POST /api/b2Delete` | Firebase token | Delete B2 object |
| `POST /api/linkPreview` | Firebase token | Server-side OG/meta tag extraction |

## Architecture decisions

- Push server routes integrated into the existing `artifacts/api-server` TypeScript project (not the standalone `duoshield_server/` JS app) so all code shares one workflow and one process.
- Firebase Admin SDK uses `GOOGLE_APPLICATION_CREDENTIALS_JSON` secret (falls back to `FIREBASE_SERVICE_ACCOUNT_JSON`) — no file on disk.
- `firebase-setup.mjs` uses the service account JSON directly (no FlutterFire CLI needed) to register the Android app and generate `google-services.json` + `firebase_options.dart`.
- Flutter `AppConstants.pushServerUrl` points to this Replit server's dev domain at `/api`.

## Product

DuoShield is an Android-only encrypted messaging app:
- 1:1 and group chats encrypted with Signal protocol
- WebRTC audio/video calls via Cloudflare TURN
- PIN + biometric app lock; duress PIN triggers full wipe
- Encrypted media uploads to Backblaze B2 (AES-256-GCM)
- Seed-phrase-based identity (BIP39 → custom base32 user ID)
- Full backup/restore from encrypted `.dsbak` files

## Required Environment Secrets

| Secret | Purpose |
|---|---|
| `GOOGLE_APPLICATION_CREDENTIALS_JSON` | Firebase Admin SDK service account JSON |
| `AUTH_SECRET` | Shared secret for `/api/mintToken` — must match value in Flutter app |
| `CLOUDFLARE_TURN_API_TOKEN` | Cloudflare TURN API token (optional — calls fail gracefully) |
| `CLOUDFLARE_TURN_KEY_ID` | Cloudflare TURN key ID (optional) |
| `B2_KEY_ID` | Backblaze B2 application key ID (optional) |
| `B2_APPLICATION_KEY` | Backblaze B2 application key (optional) |
| `B2_BUCKET_NAME` | Backblaze B2 bucket name (optional) |
| `B2_ENDPOINT` | Backblaze B2 S3 endpoint (optional) |

## Render Deployment

Push server is deployed at **https://duoshield-server.onrender.com**

- Render service ID: `srv-d9e8e0v41pts73eemuug`
- Dashboard: https://dashboard.render.com/web/srv-d9e8e0v41pts73eemuug
- GitHub source: https://github.com/kumarclaude4-hash/duoshield-server (public repo, auto-deploys on push)
- `FIREBASE_SERVICE_ACCOUNT_JSON` set from `GOOGLE_APPLICATION_CREDENTIALS_JSON` at deploy time
- To redeploy: push to `duoshield_server/` → `git push` in that folder, Render auto-deploys

Flutter `pushServerUrl` now points to `https://duoshield-server.onrender.com`.

## Flutter Build

```bash
cd duoshield_app
flutter pub get
flutter build apk --debug
```

Requires Flutter 3.32 (`flutter332` on Nix).  
`google-services.json` is already generated at `android/app/google-services.json`.  
`firebase_options.dart` is already generated at `lib/firebase_options.dart`.  
Set `AUTH_SECRET` in `lib/screens/auth/display_name_screen.dart` and `restore_from_seed_screen.dart`.

## Gotchas

- Run `node scripts/firebase-setup.mjs` any time you change the Firebase project or need to regenerate `google-services.json`.
- The `duoshield_server/` directory is the original reference JS server — it is NOT wired into any workflow. All routes are in `artifacts/api-server/`.
- `CLOUDFLARE_TURN_API_TOKEN`, B2 keys are optional — routes return 503/500 if not set.
- `AUTH_SECRET` must be set or `/api/mintToken` will always return 403.

## User preferences

_Populate as you build — explicit user instructions worth remembering across sessions._

## Pointers

- See the `pnpm-workspace` skill for workspace structure, TypeScript setup, and package details
