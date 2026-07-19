# DuoShield — Deployment Guide

Complete step-by-step instructions for deploying all three components:
1. **Firebase** (Auth, Firestore, FCM)
2. **Push server** (Render.com)
3. **Android APK** (release build)

---

## Prerequisites

- Firebase project created at https://console.firebase.google.com
- Render.com account (free tier is fine for the push server)
- Cloudflare Zero Trust account (for TURN credentials)
- Backblaze B2 account (for encrypted media storage)
- Flutter SDK installed (`flutter doctor` passes)

---

## Step 1 — Firebase Setup

### 1a. Configure Flutter app
```bash
# Install FlutterFire CLI (one-time)
dart pub global activate flutterfire_cli

# Run from the workspace root — select your Firebase project
cd duoshield_app
flutterfire configure --project=<YOUR_FIREBASE_PROJECT_ID>
```
This overwrites `lib/firebase_options.dart` and creates
`android/app/google-services.json`.

### 1b. Enable Firebase services
In the Firebase console:
- **Authentication** → Enable "Anonymous" (disabled, used only for custom token auth)
- **Firestore** → Create database in production mode (rules deployed next)
- **Cloud Messaging** → No extra config needed; `google-services.json` handles it

### 1c. Deploy Firestore security rules and indexes
```bash
# From workspace root
npm install -g firebase-tools   # one-time
firebase login
firebase use <YOUR_FIREBASE_PROJECT_ID>

# Deploy rules + indexes
firebase deploy --only firestore
```

---

## Step 2 — Push Server (Render.com)

### 2a. Create a Web Service on Render
- Repository: connect your repo or push `duoshield_server/` to GitHub
- Root directory: `duoshield_server`
- Build command: `npm install`
- Start command: `node src/index.js`
- Plan: Free (or Starter for always-on)
- Region: Oregon (or nearest to users)

### 2b. Set environment variables on Render
Go to your service → **Environment** and add:

| Key | Value |
|---|---|
| `NODE_ENV` | `production` |
| `AUTH_SECRET` | Any strong random string (32+ chars). **Remember this — you'll paste it into the Flutter app too.** |
| `FIREBASE_SERVICE_ACCOUNT_JSON` | The full JSON content of your Firebase service account key (from Firebase console → Project settings → Service accounts → Generate new private key). Paste the entire JSON as a single line. |
| `CLOUDFLARE_TURN_KEY_ID` | Cloudflare Zero Trust → TURN → API key ID |
| `CLOUDFLARE_TURN_API_TOKEN` | Cloudflare Zero Trust → TURN → API key / token |
| `B2_KEY_ID` | Backblaze B2 → Application Keys → keyID |
| `B2_APPLICATION_KEY` | Backblaze B2 → Application Keys → applicationKey |
| `B2_BUCKET_NAME` | Your B2 bucket name (e.g. `duoshield-media`) |
| `B2_ENDPOINT` | Your B2 S3-compatible endpoint (e.g. `https://s3.us-west-004.backblazeb2.com`) |
| `B2_PRESIGN_TTL` | `3600` |

### 2c. Verify the server is running
```bash
curl https://duoshield.onrender.com/healthz
# Expected: {"status":"ok","ts":1720000000000}
```

---

## Step 3 — Flutter App — Set the AUTH_SECRET

In two files, replace `'AUTH_SECRET'` with the exact same value you set on Render:

**`duoshield_app/lib/screens/auth/display_name_screen.dart`** (line ~50):
```dart
final token = await PushServer.mintToken(userId, 'YOUR_AUTH_SECRET_HERE');
```

**`duoshield_app/lib/screens/auth/restore_from_seed_screen.dart`** (line ~70):
```dart
final token = await PushServer.mintToken(derivedUserId, 'YOUR_AUTH_SECRET_HERE');
```

---

## Step 4 — Android Release Build

### 4a. Generate a release keystore (one-time)
```bash
cd duoshield_app/android/app
keytool -genkey -v \
  -keystore duoshield-release.keystore \
  -alias duoshield \
  -keyalg RSA -keysize 2048 -validity 10000
```
**Back up `duoshield-release.keystore` securely — losing it means you can never update the app.**

### 4b. Set signing env vars (or add to `key.properties`)
```bash
export KEY_STORE_PASSWORD=<your_keystore_password>
export KEY_ALIAS=duoshield
export KEY_PASSWORD=<your_key_password>
```

### 4c. Add app launcher icons
Place a 1024×1024 PNG at `duoshield_app/assets/images/icon.png`, then run:
```bash
cd duoshield_app
flutter pub add flutter_launcher_icons --dev
# Add to pubspec.yaml flutter_launcher_icons config, then:
dart run flutter_launcher_icons
```
Or manually place `ic_launcher.png` in each `mipmap-*` directory under
`android/app/src/main/res/`.

### 4d. Get dependencies and build
```bash
cd duoshield_app
flutter pub get
flutter build apk --release
```

Output APK: `build/app/outputs/flutter-apk/app-release.apk`

---

## Step 5 — Verification

After deploying, test end-to-end:
1. Install APK on two Android devices (minSdk 26 = Android 8.0+)
2. Create account on device A → note the 12 seed words
3. Create account on device B
4. Add each other by DuoShield ID
5. Send a message — verify it appears on both sides
6. Make a voice call — verify audio works both ways
7. Background device A for 35 seconds → foreground → lock screen should appear
8. Enter duress PIN → verify wipe occurs

---

## Architecture Quick Reference

```
Device A ──────────────────────────────────────────────────────────────────
  Flutter app (Signal E2E encrypted)
    │                     │
    ▼                     ▼
  Firestore           Push server (Render)
  (signaling,         /mintToken   — custom auth tokens
   messages,          /createChat  — chat doc creation
   presence)          /turnCreds   — WebRTC TURN credentials
                      /b2*         — presigned B2 media URLs
                      /linkPreview — safe server-side link scraping
    │
    ▼
  B2 Storage (AES-GCM encrypted blobs)
    │
    ▼
Device B (FCM wakeup → decrypt → display)
```

---

## Files Changed Since Initial Build

| File | Change |
|---|---|
| `firestore.rules` | NEW — full production security rules |
| `firestore.indexes.json` | NEW — compound indexes for chat/group queries |
| `firebase.json` | NEW — Firebase CLI project config |
| `duoshield_server/` | NEW — complete Node.js push server |
| `duoshield_app/pubspec.yaml` | Added `photo_view: ^0.14.0` |
| `duoshield_app/lib/core/theme.dart` | Fixed `dsTheme` export, `WidgetStateProperty` migration |
| `duoshield_app/lib/models/call_record.dart` | Rewritten with correct field names |
| `duoshield_app/lib/db/app_database.dart` | Schema updated to match `CallRecord` |
| `duoshield_app/lib/db/call_dao.dart` | Added `clearAll()` method |
| `duoshield_app/android/app/build.gradle` | Added release signing config |
