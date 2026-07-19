# DuoShield Flutter App — Agent Handoff Document

## Project Status: COMPLETE (all source files generated)

All 76 Dart source files have been generated. The project is ready for Flutter build setup.

---

## Directory Layout

```
duoshield_app/
├── pubspec.yaml                        ← All dependencies declared
├── assets/images/                      ← Place app icons/images here
├── lib/
│   ├── main.dart                       ← Entry point (Firebase init, SecurePrefs init, Notifications)
│   ├── app.dart                        ← MaterialApp.router + lifecycle observer
│   ├── router.dart                     ← GoRouter with all 20+ named routes
│   ├── firebase_options.dart           ← PLACEHOLDER — must replace with flutterfire configure output
│   ├── core/
│   │   ├── colors.dart                 ← All brand colors (dark purple theme)
│   │   ├── constants.dart              ← All string keys, URLs, timing constants
│   │   ├── extensions.dart             ← String.initials, int.toDateTime(), DateTime.toConversationTime()
│   │   ├── theme.dart                  ← ThemeData (dsTheme)
│   │   └── typography.dart             ← AppTypography text styles
│   ├── models/
│   │   ├── message.dart
│   │   ├── contact.dart
│   │   ├── conversation.dart
│   │   ├── group.dart
│   │   ├── group_member.dart
│   │   └── call_record.dart
│   ├── crypto/
│   │   ├── seed_phrase_helper.dart     ← BIP39 → base32 → XXXXX-XXXXX-XXX user ID
│   │   ├── pin_hasher.dart             ← SHA-256 PIN hashing
│   │   ├── database_key_provider.dart  ← HKDF-SHA256(uid bytes, "db_key", 32)
│   │   ├── backup_crypto_helper.dart   ← AES-256-GCM backup encryption
│   │   ├── group_crypto_helper.dart    ← Group key wrap/unwrap
│   │   └── signal_cipher_helper.dart   ← Signal protocol cipher helpers
│   ├── db/
│   │   ├── app_database.dart           ← SQLCipher DB init, schema v12
│   │   ├── message_dao.dart
│   │   ├── contact_dao.dart
│   │   ├── conversation_dao.dart
│   │   ├── group_dao.dart
│   │   ├── call_dao.dart
│   │   └── signal_store_dao.dart
│   ├── security/
│   │   ├── secure_prefs.dart           ← FlutterSecureStorage wrapper (EncryptedSharedPrefs on Android)
│   │   ├── app_lock_manager.dart       ← Background timer → lock / auto sign-out
│   │   └── duress_manager.dart         ← Wipe: clears DB + SecurePrefs + signs out
│   ├── network/
│   │   ├── push_server.dart            ← HTTP client for https://duoshield.onrender.com
│   │   └── b2_storage.dart             ← B2 presigned URL upload/download (AES-GCM encrypted)
│   ├── services/
│   │   ├── auth_service.dart           ← Firebase Auth wrapper
│   │   ├── firestore_service.dart      ← All Firestore read/write helpers
│   │   ├── presence_service.dart       ← Online/offline presence via Firestore
│   │   ├── notification_service.dart   ← FCM + flutter_local_notifications
│   │   ├── signal_service.dart         ← Pre-key rotation + replenishment
│   │   └── backup_service.dart         ← Local .dsbak file export/import
│   ├── providers/
│   │   ├── auth_provider.dart          ← StreamProvider<User?>
│   │   ├── conversation_provider.dart
│   │   ├── message_provider.dart
│   │   ├── contact_provider.dart
│   │   └── settings_provider.dart      ← StateNotifierProvider<SettingsState>
│   ├── widgets/
│   │   ├── matrix_rain_view.dart       ← Animated matrix rain background
│   │   ├── typing_dots_view.dart       ← 3-dot animated typing indicator
│   │   ├── waveform_view.dart          ← Audio waveform seekbar
│   │   ├── ds_text_field.dart          ← Branded text input
│   │   ├── ds_button.dart              ← Gradient / outline button
│   │   ├── ds_bottom_sheet.dart        ← Modal bottom sheet helper
│   │   ├── message_bubble.dart         ← Full-featured chat bubble (reactions, edit, delete, media, reply)
│   │   ├── conversation_tile.dart      ← Swipe-to-archive conversation list item
│   │   └── contact_tile.dart          ← Contact list item
│   └── screens/
│       ├── splash/splash_screen.dart
│       ├── auth/
│       │   ├── sign_in_screen.dart
│       │   ├── display_name_screen.dart
│       │   ├── seed_phrase_display_screen.dart
│       │   └── restore_from_seed_screen.dart
│       ├── lock/lock_screen.dart        ← PIN + biometric unlock, duress PIN detection
│       ├── conversations/conversation_list_screen.dart
│       ├── chat/chat_screen.dart        ← Full 1:1 chat (send, reply, edit, delete, reactions, typing, status)
│       ├── group_chat/group_chat_screen.dart
│       ├── create_group/create_group_screen.dart
│       ├── add_contact/add_contact_screen.dart  ← Enter ID / Scan QR / Share link tabs
│       ├── contact_detail/contact_detail_screen.dart
│       ├── call/
│       │   ├── call_screen.dart         ← WebRTC audio/video call (offer/answer/ICE via Firestore)
│       │   └── call_history_screen.dart
│       ├── safety_numbers/safety_numbers_screen.dart
│       ├── media_viewer/media_viewer_screen.dart
│       └── settings/
│           ├── settings_screen.dart
│           ├── pin_settings_screen.dart
│           ├── duress_pin_screen.dart
│           ├── profile_settings_screen.dart
│           ├── backup_settings_screen.dart
│           ├── privacy_settings_screen.dart
│           └── notification_settings_screen.dart
└── android/
    ├── build.gradle                    ← Root build with google-services plugin
    ├── settings.gradle
    ├── gradle.properties
    └── app/
        ├── build.gradle                ← applicationId com.duoshield.app, minSdk 26, targetSdk 34
        ├── proguard-rules.pro
        └── src/main/
            ├── AndroidManifest.xml     ← All permissions, deep link duoshield://add/<userId>
            ├── kotlin/com/duoshield/app/MainActivity.kt
            └── res/
                ├── xml/network_security_config.xml
                ├── values/styles.xml
                ├── values/colors.xml
                └── drawable/launch_background.xml
```

---

## Setup Steps for the Developer

### 1. Install Flutter (if not done)
```
flutter332 doctor
```

### 2. Add Firebase (REQUIRED — app won't run without this)
```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# In duoshield_app/:
flutterfire configure --project=<YOUR_FIREBASE_PROJECT_ID>
```
This will overwrite `lib/firebase_options.dart` with real credentials and create:
- `android/app/google-services.json`

### 3. Get dependencies
```bash
cd duoshield_app
flutter pub get
```

### 4. Create mipmap icon directories (required for build)
Place a 192×192 PNG icon at:
- `android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png`
- `android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png`
- `android/app/src/main/res/mipmap-xhdpi/ic_launcher.png`
- `android/app/src/main/res/mipmap-hdpi/ic_launcher.png`
- `android/app/src/main/res/mipmap-mdpi/ic_launcher.png`

Or use `flutter_launcher_icons` package to generate them automatically.

### 5. Set the auth secret
In `lib/screens/auth/display_name_screen.dart` and `restore_from_seed_screen.dart`, replace `'AUTH_SECRET'` with the actual shared secret configured on your push server (`https://duoshield.onrender.com`).

### 6. Build the debug APK
```bash
cd duoshield_app
flutter build apk --debug
```

### 7. Build the release APK
```bash
# First set up a keystore for signing
keytool -genkey -v -keystore duoshield.keystore -alias duoshield \
  -keyalg RSA -keysize 2048 -validity 10000

# Then build
flutter build apk --release
```

---

## Architecture Notes

### Authentication Flow
1. User creates account → `SeedPhraseHelper.generateMnemonic()` → BIP39 12 words
2. `SeedPhraseHelper.deriveUserId(mnemonic)` → custom base32 XXXXX-XXXXX-XXX format
3. Custom token minted via POST `https://duoshield.onrender.com/mintToken`
4. Firebase Auth `signInWithCustomToken(token)`
5. Identity keys uploaded to Firestore `identities/<userId>`

### Database Encryption
- SQLCipher via `sqflite_sqlcipher` package
- Key derived: `HKDF-SHA256(utf8(uid), "db_key", 32)` → base64 → SQLCipher password
- `AppDatabase.init(uid)` must be called after sign-in (currently called from `main.dart` — **add this call!**)

### App Lock
- `AppLockManager` tracks foreground/background timestamps
- 30s background → show lock screen (PIN/biometric)
- 15min background → auto sign-out
- Duress PIN → `DuressManager.performWipe()` → erase everything, sign out

### Messaging Encryption
- Signal Protocol via `libsignal_protocol_dart`
- `signal_cipher_helper.dart` wraps encrypt/decrypt
- Pre-keys uploaded to Firestore `identities/<userId>.preKeys`
- Signed pre-key rotates every 7 days (checked at app start)

### WebRTC Calls
- Signaling via Firestore `calls/<callId>` document
- Offer → caller writes, callee reads and writes answer
- ICE candidates stored as arrays in Firestore doc
- TURN credentials fetched from push server `/turnCredentials`
- Call recording → `call_history` SQLCipher table

### Key Missing Integration (TODO for next agent/developer)
1. **`google_services.json`** — Must be generated by `flutterfire configure` (see Setup Steps above)
2. **Push server auth secret** — Replace `'AUTH_SECRET'` placeholder in:
   - `lib/screens/auth/display_name_screen.dart` line ~50
   - `lib/screens/auth/restore_from_seed_screen.dart` line ~70

All other previously noted issues have been resolved:
- ✅ `AppDatabase.init(uid)` — now called in `splash_screen.dart` after user is resolved
- ✅ `photo_view: ^0.14.0` — added to `pubspec.yaml`
- ✅ `dsTheme` — `theme.dart` now exports `final ThemeData dsTheme = buildAppTheme()`
- ✅ `MaterialStateProperty` — migrated to `WidgetStateProperty` in `theme.dart`
- ✅ `colorScheme.background` (deprecated) — removed from `theme.dart`

---

## pubspec.yaml Key Dependencies

| Package | Version | Purpose |
|---|---|---|
| `firebase_core` | ^3.1.0 | Firebase |
| `firebase_auth` | ^5.1.0 | Auth |
| `cloud_firestore` | ^5.0.0 | Firestore |
| `firebase_messaging` | ^15.0.0 | FCM push |
| `libsignal_protocol_dart` | ^0.3.0 | Signal E2E |
| `sqflite_sqlcipher` | ^2.3.0+1 | Encrypted SQLite |
| `flutter_riverpod` | ^2.5.1 | State management |
| `go_router` | ^14.2.0 | Navigation |
| `flutter_webrtc` | ^0.10.6 | WebRTC calls |
| `flutter_secure_storage` | ^9.0.0 | Secure prefs |
| `local_auth` | ^2.2.0 | Biometric |
| `pointycastle` | ^3.9.1 | AES-GCM crypto |
| `bip39` | ^1.0.6 | Seed phrase |
| `mobile_scanner` | ^5.1.0 | QR scan |
| `qr_flutter` | ^4.1.0 | QR display |

---

## Critical Bug Fixes Applied

1. **`b2_storage.dart`** — Removed invalid inline `import 'dart:convert'` statements that were inside method bodies
2. **`backup_service.dart`** — Removed invalid inline `import '../models/message.dart'` inside `_messageFromMap()` method; rewrote correctly
3. **`call_record.dart`** — Rewrote model to use `peerUid`, `peerName`, `type`, `status`, `durationSecs` fields matching what `call_screen.dart` and `call_history_screen.dart` use
4. **`app_database.dart`** — Updated `call_history` table schema to match new `CallRecord` model fields
5. **`secure_prefs.dart`** — Added `init()` method and `defaultValue` parameter to `getBool()`
6. **`app_lock_manager.dart`** — Added `onAppBackgrounded()` and `onAppResumed(GoRouter)` methods referenced from `app.dart`
7. **`constants.dart`** — Added all missing prefs constants (`prefSafetyNumVerified`, `prefSafetyNumKey`, `prefReadReceiptsEnabled`, `prefShowLastSeen`, `prefTypingIndicators`, `prefLinkPreviews`, `prefNotif*`)

---

## Files That Need Additional Work (for next phase)

### Firebase setup (REQUIRED — app cannot run without this)
Run `flutterfire configure` to generate `google-services.json` and overwrite `firebase_options.dart`.

### Push server auth secret
Set the shared secret in two files (search for `'AUTH_SECRET'`):
- `lib/screens/auth/display_name_screen.dart`
- `lib/screens/auth/restore_from_seed_screen.dart`

---

## Route Map

| Route | Screen |
|---|---|
| `/` | SplashScreen |
| `/sign-in` | SignInScreen |
| `/display-name` | DisplayNameScreen |
| `/seed-phrase-display` | SeedPhraseDisplayScreen |
| `/restore-from-seed` | RestoreFromSeedScreen |
| `/lock` | LockScreen |
| `/conversations` | ConversationListScreen |
| `/chat/:conversationId` | ChatScreen |
| `/group-chat/:groupId` | GroupChatScreen |
| `/create-group` | CreateGroupScreen |
| `/add-contact` | AddContactScreen |
| `/contact-detail` | ContactDetailScreen |
| `/call` | CallScreen |
| `/call-history` | CallHistoryScreen |
| `/settings` | SettingsScreen |
| `/settings/pin` | PinSettingsScreen |
| `/settings/duress-pin` | DuressPinScreen |
| `/settings/profile` | ProfileSettingsScreen |
| `/settings/backup` | BackupSettingsScreen |
| `/settings/privacy` | PrivacySettingsScreen |
| `/settings/notifications` | NotificationSettingsScreen |
| `/safety-numbers` | SafetyNumbersScreen |
| `/media-viewer` | MediaViewerScreen |

---

*Generated by Agent — 76 Dart source files, 4 Kotlin/XML files, 5 Android build files*
