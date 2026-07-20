# DuoShield — Project Overview

## What This Is

DuoShield is an end-to-end encrypted messaging app for Android with:
- **Signal Protocol** encryption for 1:1 and group messaging
- **WebRTC** audio/video calls with Cloudflare TURN
- **SQLCipher** encrypted local database
- **Firebase Auth + Firestore** for identity and real-time sync
- **BIP39 seed phrases** as user identity (no phone number or email required)

## Repository Layout

```
duoshield_app/        Flutter Android app (76 Dart source files)
duoshield_server/     Node.js/Express push server (deploy to Render)
.github/workflows/    GitHub Actions CI — builds & signs release APK
lib/                  Shared TS libraries (api-spec, api-client-react)
artifacts/            Replit workspace artifacts (api-server, mockup-sandbox)
```

## GitHub Actions CI

**Workflow:** `.github/workflows/build-apk.yml`
**Triggers:** Push to `main` touching `duoshield_app/**` or the workflow file, plus manual `workflow_dispatch`.

### Signing setup (automatic fallback)
The workflow auto-generates a CI keystore when secrets are missing or the alias is mismatched:
1. If `KEYSTORE_BASE64` + `KEY_STORE_PASSWORD` + `KEY_ALIAS` secrets are all set **and** the alias exists in the decoded keystore → uses the provided keystore (production signing).
2. Otherwise → generates a fresh RSA-2048 keystore with alias `duoshield` for CI signing.

### GitHub Actions secrets (for production signing)
| Secret | Value |
|---|---|
| `KEYSTORE_BASE64` | `base64 -w0 duoshield-release.keystore` |
| `KEY_STORE_PASSWORD` | keystore password |
| `KEY_ALIAS` | key alias (must match alias inside the JKS) |
| `KEY_PASSWORD` | key password |
| `GOOGLE_SERVICES_JSON` | full contents of `google-services.json` |

## Flutter App — Required Setup (for local dev)

1. **Firebase** — run `flutterfire configure --project=<YOUR_PROJECT_ID>` inside `duoshield_app/` to generate `firebase_options.dart` and `android/app/google-services.json`.
2. **Push server auth secret** — replace `'AUTH_SECRET'` in:
   - `lib/screens/auth/display_name_screen.dart` (line ~50)
   - `lib/screens/auth/restore_from_seed_screen.dart` (line ~70)

## Push Server — Deployment

The server is deployed to Render at `https://duoshield.onrender.com`. See `duoshield_server/README.md` for full env var setup (Firebase service account, `AUTH_SECRET`, Cloudflare TURN, Backblaze B2).

## User Preferences

- Use `GIT_PAT` secret (not `GITHUB_PAT`) for all GitHub API/push operations.
- Keep CI logs minimal — no `--verbose` flag; only print error summary on failure.
