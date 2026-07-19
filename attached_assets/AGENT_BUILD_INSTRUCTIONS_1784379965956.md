# DuoShield Flutter — Agent Build Instructions
**Version:** 1.0 | **Date:** 2026-07-18
**Purpose:** Complete, zero-ambiguity build specification for a Flutter replica of DuoShield Android.
**Rule:** Every widget, every tap, every field, every API call, every error string is defined here. Do NOT infer or invent anything not listed. If something is not in this document, ask before building it.

---

## TABLE OF CONTENTS

1. [Environment & SDK](#1-environment--sdk)
2. [Project Bootstrap](#2-project-bootstrap)
3. [Color System](#3-color-system)
4. [Typography](#4-typography)
5. [Dependencies (pubspec.yaml)](#5-dependencies-pubspecyaml)
6. [Folder Structure](#6-folder-structure)
7. [Data Models](#7-data-models)
8. [Local Database (SQLite/SQLCipher)](#8-local-database-sqlitesqlcipher)
9. [Crypto Layer](#9-crypto-layer)
10. [Security Layer](#10-security-layer)
11. [Firebase / Firestore](#11-firebase--firestore)
12. [Push Server API](#12-push-server-api)
13. [B2 Storage](#13-b2-storage)
14. [Screen: Splash](#14-screen-splash)
15. [Screen: Sign In](#15-screen-sign-in)
16. [Screen: Display Name](#16-screen-display-name)
17. [Screen: Seed Phrase Display](#17-screen-seed-phrase-display)
18. [Screen: Restore From Seed](#18-screen-restore-from-seed)
19. [Screen: Conversation List](#19-screen-conversation-list)
20. [Screen: Chat](#20-screen-chat)
21. [Screen: Group Chat](#21-screen-group-chat)
22. [Screen: Create Group](#22-screen-create-group)
23. [Screen: Add Contact](#23-screen-add-contact)
24. [Screen: Contact Detail](#24-screen-contact-detail)
25. [Screen: Call](#25-screen-call)
26. [Screen: Call History](#26-screen-call-history)
27. [Screen: Lock Screen](#27-screen-lock-screen)
28. [Screen: Settings](#28-screen-settings)
29. [Screen: Safety Numbers](#29-screen-safety-numbers)
30. [Screen: Media Viewer](#30-screen-media-viewer)
31. [Screen: Backup & Restore Settings](#31-screen-backup--restore-settings)
32. [Notifications](#32-notifications)
33. [Deep Links](#33-deep-links)
34. [Background Services](#34-background-services)
35. [Navigation (GoRouter)](#35-navigation-gorouter)
36. [State Management](#36-state-management)
37. [Custom Widgets](#37-custom-widgets)
38. [Build & Run](#38-build--run)
39. [Testing Checklist](#39-testing-checklist)

---

## 1. ENVIRONMENT & SDK

```
Flutter version : 3.32.0  (package: flutter332 on Nix)
Dart version    : 3.8.x   (bundled with Flutter 3.32.0)
Target platform : Android only (minSdk 26, targetSdk 34, compileSdk 34)
Java            : 17
Kotlin          : 1.9.22
Gradle          : 8.x (AGP 8.3.x)
```

**Flutter channel:** stable.  
**Do not** target iOS, Web, or Desktop — exclude all platform folders except `android/`.  
**SQLCipher** wraps SQLite with AES-256-CBC encryption. Use `sqflite_sqlcipher` package.  
**Signal protocol** library: use Dart re-implementation `libsignal_protocol_dart`. Do not use native JNI bindings.

---

## 2. PROJECT BOOTSTRAP

Run exactly:
```bash
flutter332 create --org com.duoshield --project-name duoshield_app --platforms android duoshield_app
cd duoshield_app
```

After creation:
- Delete `ios/`, `linux/`, `macos/`, `web/`, `windows/` directories.
- Set `android/app/build.gradle` → `applicationId "com.duoshield.app"`.
- Set `android/app/build.gradle` → `minSdkVersion 26`.
- Set `android/app/build.gradle` → `targetSdkVersion 34`.
- Place `google-services.json` in `android/app/`.
- Add `apply plugin: 'com.google.gms.google-services'` at bottom of `android/app/build.gradle`.
- Add `classpath 'com.google.gms:google-services:4.4.1'` to root `build.gradle` dependencies.

---

## 3. COLOR SYSTEM

Use these exact hex values everywhere. No other colors unless explicitly stated in a section.

| Token                 | Hex       | Usage                                           |
|-----------------------|-----------|-------------------------------------------------|
| `colorBackground`     | `#191620` | All screen backgrounds                          |
| `colorSurface`        | `#24202E` | Cards, bottom sheets, dialogs                   |
| `colorSurfaceVariant` | `#2E2A3A` | Elevated cards, input backgrounds               |
| `colorAccent`         | `#9A81FF` | Primary buttons, FAB, active icons, links       |
| `colorAccentDark`     | `#7A61DF` | Button pressed state, gradient stop 2           |
| `colorBubbleMine`     | `#2A2040` | Outgoing message bubble background              |
| `colorBubbleTheirs`   | `#1E1B2C` | Incoming message bubble background              |
| `colorOnAccent`       | `#FFFFFF` | Text on accent-colored buttons                  |
| `colorTextPrimary`    | `#F0EEF8` | Primary text                                    |
| `colorTextSecondary`  | `#9E9AB2` | Subtitle text, timestamps, hints                |
| `colorTextMuted`      | `#6B6880` | Placeholder text, disabled text                 |
| `colorDivider`        | `#2E2A3A` | List dividers, borders                          |
| `colorError`          | `#FF5252` | Error text, destructive actions                 |
| `colorSuccess`        | `#4CAF50` | Online indicator, success toasts                |
| `colorWarning`        | `#FFC107` | Warning banners                                 |
| `colorInputBg`        | `#1A1726` | TextField fill color                            |
| `colorIconDefault`    | `#9E9AB2` | Unselected nav icons, toolbar icons             |

**Gradient** — used on primary buttons only:
```dart
LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFF9A81FF), Color(0xFF7A61DF), Color(0xFF6A51CF)],
  stops: [0.0, 0.5, 1.0],
)
```

---

## 4. TYPOGRAPHY

Font family: **Inter** (Google Fonts).  
Load via `google_fonts` package. Apply globally in `ThemeData`.

| Style              | Font     | Size | Weight  | Color              |
|--------------------|----------|------|---------|--------------------|
| `displayLarge`     | Inter    | 28sp | Bold    | `colorTextPrimary` |
| `headlineMedium`   | Inter    | 22sp | SemiBold| `colorTextPrimary` |
| `titleLarge`       | Inter    | 18sp | SemiBold| `colorTextPrimary` |
| `titleMedium`      | Inter    | 16sp | Medium  | `colorTextPrimary` |
| `bodyLarge`        | Inter    | 15sp | Regular | `colorTextPrimary` |
| `bodyMedium`       | Inter    | 14sp | Regular | `colorTextPrimary` |
| `bodySmall`        | Inter    | 12sp | Regular | `colorTextSecondary`|
| `labelSmall`       | Inter    | 10sp | Regular | `colorTextMuted`   |

---

## 5. DEPENDENCIES (pubspec.yaml)

Add exactly these packages. No others unless a section explicitly requires one.

```yaml
dependencies:
  flutter:
    sdk: flutter
  # Firebase
  firebase_core: ^3.1.0
  firebase_auth: ^5.1.0
  cloud_firestore: ^5.0.0
  firebase_messaging: ^15.0.0
  firebase_storage: ^12.0.0

  # Signal Protocol
  libsignal_protocol_dart: ^0.3.0

  # Local DB (encrypted)
  sqflite_sqlcipher: ^2.3.0+1

  # State Management
  flutter_riverpod: ^2.5.1
  riverpod_annotation: ^2.3.5

  # Navigation
  go_router: ^14.2.0

  # Crypto / Encoding
  crypto: ^3.0.3
  pointycastle: ^3.9.1
  bip39: ^1.0.6
  convert: ^3.1.1
  base32: ^2.1.3

  # Media
  image_picker: ^1.1.1
  file_picker: ^8.0.0
  video_player: ^2.8.6
  just_audio: ^0.9.39
  record: ^5.1.0
  cached_network_image: ^3.3.1
  flutter_cache_manager: ^3.3.1

  # WebRTC
  flutter_webrtc: ^0.10.6

  # QR Code
  qr_flutter: ^4.1.0
  mobile_scanner: ^5.1.0

  # UI Utilities
  google_fonts: ^6.2.1
  flutter_animate: ^4.5.0
  shimmer: ^3.0.0
  intl: ^0.19.0
  url_launcher: ^6.3.0
  share_plus: ^9.0.0
  path_provider: ^2.1.3
  permission_handler: ^11.3.1
  local_auth: ^2.2.0
  flutter_local_notifications: ^17.2.0
  workmanager: ^0.5.2
  connectivity_plus: ^6.0.3
  device_info_plus: ^10.1.0
  package_info_plus: ^8.0.0
  http: ^1.2.1
  dio: ^5.4.3

  # One Signal Push
  onesignal_flutter: ^5.2.5

dev_dependencies:
  flutter_test:
    sdk: flutter
  riverpod_generator: ^2.4.0
  build_runner: ^2.4.9
  flutter_lints: ^4.0.0
```

---

## 6. FOLDER STRUCTURE

Create exactly this structure under `lib/`:

```
lib/
├── main.dart
├── app.dart                         # MaterialApp.router + ThemeData
├── router.dart                      # GoRouter configuration
│
├── core/
│   ├── constants.dart               # Push server URL, Firestore keys, SharedPrefs keys
│   ├── colors.dart                  # All color tokens as const Color
│   ├── theme.dart                   # ThemeData
│   ├── typography.dart              # TextStyles
│   └── extensions.dart             # String / DateTime helpers
│
├── crypto/
│   ├── seed_phrase_helper.dart      # BIP39 + HKDF
│   ├── pin_hasher.dart              # PBKDF2
│   ├── signal_cipher_helper.dart    # Signal encrypt/decrypt
│   ├── database_key_provider.dart   # HKDF → DB key
│   ├── backup_crypto_helper.dart    # AES-GCM for backup files
│   └── group_crypto_helper.dart     # AES-GCM group key
│
├── db/
│   ├── app_database.dart            # SQLCipher open/migrate
│   ├── message_dao.dart
│   ├── contact_dao.dart
│   ├── conversation_dao.dart
│   ├── group_dao.dart
│   ├── signal_store_dao.dart        # Sessions, PreKeys, Identities
│   └── call_dao.dart
│
├── models/
│   ├── message.dart
│   ├── contact.dart
│   ├── conversation.dart
│   ├── group.dart
│   ├── group_member.dart
│   └── call_record.dart
│
├── security/
│   ├── app_lock_manager.dart        # PIN/biometric lock state
│   ├── secure_prefs.dart            # EncryptedSharedPreferences equivalent
│   └── duress_manager.dart          # Duress PIN + silent wipe
│
├── network/
│   ├── push_server.dart             # All /mintToken, /createChat, etc.
│   └── b2_storage.dart             # B2 upload/download/delete
│
├── services/
│   ├── auth_service.dart            # Firebase custom-token sign-in
│   ├── firestore_service.dart       # Realtime listeners
│   ├── signal_service.dart          # X3DH session setup, prekey management
│   ├── call_service.dart            # WebRTC peer connection
│   ├── notification_service.dart    # FCM + OneSignal
│   ├── backup_service.dart          # Backup / Restore
│   └── presence_service.dart        # Online/last-seen heartbeat
│
├── providers/
│   ├── auth_provider.dart
│   ├── conversation_provider.dart
│   ├── message_provider.dart
│   ├── contact_provider.dart
│   ├── group_provider.dart
│   └── settings_provider.dart
│
├── widgets/
│   ├── matrix_rain_view.dart        # CustomPainter: falling glyphs
│   ├── waveform_view.dart           # CustomPainter: voice waveform
│   ├── typing_dots_view.dart        # Animated typing indicator
│   ├── key_orbit_view.dart          # Rotating keys animation
│   ├── message_bubble.dart          # Chat bubble (in/out)
│   ├── conversation_tile.dart       # List item for conversations
│   ├── contact_tile.dart            # List item for contacts
│   ├── ds_text_field.dart           # Shared styled TextField
│   ├── ds_button.dart               # Primary gradient button
│   └── ds_bottom_sheet.dart         # Styled modal bottom sheet
│
└── screens/
    ├── splash/splash_screen.dart
    ├── auth/
    │   ├── sign_in_screen.dart
    │   ├── display_name_screen.dart
    │   ├── seed_phrase_display_screen.dart
    │   └── restore_from_seed_screen.dart
    ├── conversations/
    │   ├── conversation_list_screen.dart
    │   └── conversation_list_controller.dart
    ├── chat/
    │   ├── chat_screen.dart
    │   └── chat_controller.dart
    ├── group_chat/
    │   ├── group_chat_screen.dart
    │   └── group_chat_controller.dart
    ├── create_group/create_group_screen.dart
    ├── add_contact/add_contact_screen.dart
    ├── contact_detail/contact_detail_screen.dart
    ├── call/call_screen.dart
    ├── call_history/call_history_screen.dart
    ├── lock/lock_screen.dart
    ├── settings/
    │   ├── settings_screen.dart
    │   ├── privacy_settings_screen.dart
    │   ├── notifications_settings_screen.dart
    │   ├── appearance_settings_screen.dart
    │   └── backup_settings_screen.dart
    ├── safety_numbers/safety_numbers_screen.dart
    └── media_viewer/media_viewer_screen.dart
```

---

## 7. DATA MODELS

### 7.1 Message
```dart
class Message {
  final String id;           // Firestore doc ID
  final String chatId;       // Parent conversation ID
  final String senderId;     // UID of sender
  final String text;         // Decrypted plaintext (stored locally)
  final String? mediaUrl;    // B2 path prefixed with "b2:"
  final String? mediaType;   // "image" | "video" | "audio" | "file"
  final String? mediaKey;    // Base64 AES key for media
  final int timestamp;       // Unix millis
  final String status;       // "sending" | "sent" | "delivered" | "read"
  final bool deletedForAll;  // true = show tombstone
  final String? replyToId;   // ID of parent message
  final String? reactionBy;  // Map<uid, emoji> — stored as JSON string
  final bool edited;         // true if message was edited
  final String? editedText;  // Plaintext of last edit
  final bool starred;        // User starred this message
  final bool pinned;         // Pinned to top
  final int? disappearMs;    // Milliseconds until auto-delete, null = off
  final int sigType;         // 0=legacy, 1=WHISPER, 3=PREKEY
  final String? linkPreviewUrl;
  final String? linkPreviewTitle;
  final String? linkPreviewImage;
}
```

### 7.2 Contact
```dart
class Contact {
  final String uid;           // Partner's Firebase UID
  final String userId;        // Partner's DuoShield ID (XXXXX-XXXXX-XXX)
  final String displayName;
  final String? avatarUrl;
  final String? conversationId;
  final int addedAt;          // Unix millis
  final bool blocked;
}
```

### 7.3 Conversation
```dart
class Conversation {
  final String id;             // Firestore chat doc ID
  final String partnerUid;
  final String partnerName;
  final String? partnerAvatar;
  final String lastMessage;    // Plaintext preview ≤80 chars
  final int lastMessageTs;
  final int unreadCount;
  final bool muted;
  final bool archived;
  final bool disappearing;
  final int? disappearMs;      // Active disappear timer
}
```

### 7.4 Group
```dart
class Group {
  final String id;
  final String name;
  final String? avatarUrl;
  final String createdBy;
  final int createdAt;
  final String groupKey;       // Base64 AES-256 key (encrypted per-member with Signal)
  final String lastMessage;
  final int lastMessageTs;
}
```

### 7.5 GroupMember
```dart
class GroupMember {
  final String groupId;
  final String memberUid;
  final String displayName;
  final int joinedAt;
}
```

### 7.6 CallRecord
```dart
class CallRecord {
  final String id;
  final String partnerId;
  final String partnerName;
  final bool isVideo;
  final String direction;      // "incoming" | "outgoing"
  final String outcome;        // "completed" | "missed" | "declined" | "failed"
  final int startedAt;         // Unix millis
  final int durationSeconds;
}
```

---

## 8. LOCAL DATABASE (SQLite/SQLCipher)

### 8.1 Database Open
```
File name   : duoshield.db
Version     : 12
Encryption  : AES-256-CBC via SQLCipher
Key source  : DatabaseKeyProvider.getKey(uid)   — see §9.4
```

**Do not open the database until uid is known.**  
**Key derivation:** `HKDF-SHA256(ikm=uidBytes, info="db_key", length=32)` → Base64 → SQLCipher PRAGMA key.

### 8.2 Table: messages

| Column         | Type    | Constraint           |
|----------------|---------|----------------------|
| id             | TEXT    | PRIMARY KEY          |
| chatId         | TEXT    | NOT NULL             |
| senderId       | TEXT    | NOT NULL             |
| text           | TEXT    |                      |
| mediaUrl       | TEXT    |                      |
| mediaType      | TEXT    |                      |
| mediaKey       | TEXT    |                      |
| timestamp      | INTEGER | NOT NULL             |
| status         | TEXT    | DEFAULT 'sent'       |
| deletedForAll  | INTEGER | DEFAULT 0            |
| replyToId      | TEXT    |                      |
| reactionBy     | TEXT    |                      |
| edited         | INTEGER | DEFAULT 0            |
| editedText     | TEXT    |                      |
| starred        | INTEGER | DEFAULT 0            |
| pinned         | INTEGER | DEFAULT 0            |
| disappearMs    | INTEGER |                      |
| sigType        | INTEGER | DEFAULT 0            |
| linkPreviewUrl   | TEXT  |                      |
| linkPreviewTitle | TEXT  |                      |
| linkPreviewImage | TEXT  |                      |

Index: `CREATE INDEX idx_messages_chat ON messages(chatId, timestamp DESC)`

### 8.3 Table: contacts

| Column         | Type    | Constraint           |
|----------------|---------|----------------------|
| uid            | TEXT    | PRIMARY KEY          |
| userId         | TEXT    | NOT NULL             |
| displayName    | TEXT    | NOT NULL             |
| avatarUrl      | TEXT    |                      |
| conversationId | TEXT    |                      |
| addedAt        | INTEGER | NOT NULL             |
| blocked        | INTEGER | DEFAULT 0            |

### 8.4 Table: conversations

| Column         | Type    | Constraint           |
|----------------|---------|----------------------|
| id             | TEXT    | PRIMARY KEY          |
| partnerUid     | TEXT    | NOT NULL             |
| partnerName    | TEXT    |                      |
| partnerAvatar  | TEXT    |                      |
| lastMessage    | TEXT    |                      |
| lastMessageTs  | INTEGER | DEFAULT 0            |
| unreadCount    | INTEGER | DEFAULT 0            |
| muted          | INTEGER | DEFAULT 0            |
| archived       | INTEGER | DEFAULT 0            |
| disappearing   | INTEGER | DEFAULT 0            |
| disappearMs    | INTEGER |                      |

### 8.5 Table: groups

| Column         | Type    | Constraint           |
|----------------|---------|----------------------|
| id             | TEXT    | PRIMARY KEY          |
| name           | TEXT    | NOT NULL             |
| avatarUrl      | TEXT    |                      |
| createdBy      | TEXT    | NOT NULL             |
| createdAt      | INTEGER | NOT NULL             |
| groupKey       | TEXT    | NOT NULL             |
| lastMessage    | TEXT    |                      |
| lastMessageTs  | INTEGER | DEFAULT 0            |

### 8.6 Table: group_members

| Column     | Type    | Constraint               |
|------------|---------|--------------------------|
| groupId    | TEXT    | NOT NULL, composite PK   |
| memberUid  | TEXT    | NOT NULL, composite PK   |
| displayName| TEXT    |                          |
| joinedAt   | INTEGER |                          |

`PRIMARY KEY (groupId, memberUid)`

### 8.7 Table: signal_sessions

| Column      | Type    | Constraint  |
|-------------|---------|-------------|
| address     | TEXT    | PRIMARY KEY |
| session_data| BLOB    | NOT NULL    |
| updated_at  | INTEGER | DEFAULT 0   |

### 8.8 Table: signal_prekeys

| Column   | Type    | Constraint  |
|----------|---------|-------------|
| id       | INTEGER | PRIMARY KEY |
| key_data | BLOB    | NOT NULL    |

### 8.9 Table: signal_signed_prekeys

| Column    | Type    | Constraint  |
|-----------|---------|-------------|
| id        | INTEGER | PRIMARY KEY |
| key_data  | BLOB    | NOT NULL    |
| created_at| INTEGER | DEFAULT 0   |

### 8.10 Table: signal_identities

| Column        | Type    | Constraint  |
|---------------|---------|-------------|
| address       | TEXT    | PRIMARY KEY |
| identity_key  | BLOB    | NOT NULL    |
| verified      | INTEGER | DEFAULT 0   |

### 8.11 Table: call_history

| Column          | Type    | Constraint  |
|-----------------|---------|-------------|
| id              | TEXT    | PRIMARY KEY |
| partnerId       | TEXT    | NOT NULL    |
| partnerName     | TEXT    |             |
| isVideo         | INTEGER | DEFAULT 0   |
| direction       | TEXT    | NOT NULL    |
| outcome         | TEXT    | NOT NULL    |
| startedAt       | INTEGER | NOT NULL    |
| durationSeconds | INTEGER | DEFAULT 0   |

### 8.12 Migration Rules

- Version 1→12: Create all tables above in a single migration block.
- If database open fails with key error: show `AlertDialog` title "Database Error", body "Failed to open secure database. Please restore your account.", one button "OK" → navigate to `SignInScreen`.

---

## 9. CRYPTO LAYER

### 9.1 SeedPhraseHelper

**BIP39 Mnemonic Generation**
- Word list: BIP39 English (2048 words).
- Entropy: 128 bits (12 words).
- Use `bip39` package: `generateMnemonic()` → 12-word space-separated string.

**User ID Derivation from Mnemonic**
1. Compute `seed = mnemonicToSeed(mnemonic)` — 64-byte PBKDF2 output with "mnemonic" passphrase.
2. Take first 20 bytes of seed.
3. Encode using custom base32 alphabet: `ABCDEFGHJKLMNPQRSTUVWXYZ23456789` (no I, O, 1, 0).
4. Format: characters 0–4 = group 1, 5–9 = group 2, 10–12 = group 3 → `XXXXX-XXXXX-XXX`.
5. This ID is permanent and displayed as the user's DuoShield ID.

**Identity Key Derivation**
1. `hkdf(ikm=seed[0..31], info=Uint8List.fromList(utf8.encode("identity_key")), length=32)`.
2. Result is the Curve25519 private key for Signal identity.
3. Public key = Curve25519 scalar multiplication of private key with base point.

**HKDF-SHA256 implementation:**
- Algorithm: HMAC-SHA256 based HKDF (RFC 5869).
- Salt: 32 zero bytes when no salt provided.
- Method signature: `static Uint8List hkdfSha256(Uint8List ikm, Uint8List info, int length)`.
- Do NOT use HKDF from any other package — implement RFC 5869 directly with `crypto` package.

**Mnemonic Validation**
- Split input by whitespace.
- Count words — must be exactly 12.
- Each word must exist in BIP39 English word list.
- Return `bool valid` and `String? error`.

### 9.2 PinHasher

**PIN Storage Format:** `hexSalt:hexHash`  
**Algorithm:** PBKDF2-HMAC-SHA256  
**Iterations:** 310,000  
**Salt:** 16 random bytes → hex-encoded  
**Output hash:** 32 bytes → hex-encoded  
**Input:** PIN as UTF-8 bytes  

```dart
// Hash a PIN
static String hashPin(String pin) {
  final salt = _secureRandom(16);
  final hash = _pbkdf2(utf8.encode(pin), salt, 310000, 32);
  return '${hex.encode(salt)}:${hex.encode(hash)}';
}

// Verify
static bool verifyPin(String pin, String stored) {
  final parts = stored.split(':');
  final salt = hex.decode(parts[0]);
  final expectedHash = hex.decode(parts[1]);
  final actualHash = _pbkdf2(utf8.encode(pin), salt, 310000, 32);
  return _constantTimeEquals(actualHash, expectedHash);
}
```

Use `pointycastle` for PBKDF2. Implement `_constantTimeEquals` with bitwise OR — never use `==` for hash comparison.

**Storage keys** (in SecurePrefs):
- App PIN: `app_pin_hash_<uid>`
- Duress PIN: `duress_pin_hash_<uid>`

**Legacy migration** (if key `app_pin_hash` exists without uid suffix): copy value to `app_pin_hash_<uid>`, delete old key.

### 9.3 SignalCipherHelper

**Library:** `libsignal_protocol_dart`

**Setup (first time, per contact):**
1. Fetch partner's PreKeyBundle from Firestore `identities/{partnerUid}`.
2. Run X3DH: `SessionBuilder.processPreKeyBundle(bundle)`.
3. Store session in `signal_sessions` table with address = `partnerUid`.

**Encrypt:**
```dart
// Returns SignalMessage or PreKeySignalMessage bytes
// sigType 1 = WhisperMessage (existing session)
// sigType 3 = PreKeySignalMessage (new session, includes PreKey)
static Uint8List encrypt(String address, Uint8List plaintext)
```

**Decrypt:**
```dart
// Detects message type automatically
// sigType 0 = legacy (cannot decrypt, show tombstone)
// sigType 1 = WhisperMessage
// sigType 3 = PreKeySignalMessage
static Uint8List decrypt(String address, Uint8List ciphertext, int sigType)
```

**On decrypt failure:** return null, display `"[Message could not be decrypted]"` in bubble. Do NOT throw.

**PreKey Rotation:**
- Threshold: if remaining PreKeys in Firestore < 10 → generate batch of 25.
- Track next PreKey ID in SecurePrefs key `signal_prekey_next_id`.
- Upload batch to Firestore `identities/{uid}` field `preKeys` as array of `{id, publicKey, signature}` objects using `arrayUnion`.

**Signed PreKey Rotation:**
- Check every app launch: if last rotation > 7 days → generate new Signed PreKey.
- Store previous SPK in SecurePrefs `signal_signed_prekey_prev` for 7-day grace period.
- Load order: current → if fail, try `signal_signed_prekey_prev`.
- Upload to Firestore `identities/{uid}` field `signedPreKey`.

### 9.4 DatabaseKeyProvider

```dart
static String getKey(String uid) {
  final ikm = Uint8List.fromList(utf8.encode(uid));
  final info = Uint8List.fromList(utf8.encode("db_key"));
  final keyBytes = SeedPhraseHelper.hkdfSha256(ikm, info, 32);
  return base64.encode(keyBytes);
}
```

Pass this string as the SQLCipher PRAGMA key. Never log or print this value.

### 9.5 GroupCryptoHelper

**Group key:** 32 random bytes generated by group creator.  
**Algorithm:** AES-256-GCM.  
**Nonce:** 12 random bytes, prepended to ciphertext.  
**Wire format:** `[12-byte nonce | ciphertext | 16-byte GCM tag]`.

```dart
static Uint8List encryptGroup(Uint8List key, Uint8List plaintext)
static Uint8List decryptGroup(Uint8List key, Uint8List ciphertext)
```

Group key distribution: the creator Signal-encrypts the raw 32-byte group key for each member and stores per-member encrypted copy in Firestore `groups/{groupId}/keys/{memberUid}` → field `encryptedKey` (Base64).

### 9.6 BackupCryptoHelper

**Derive backup key:** `hkdfSha256(ikm=seed[0..31], info=utf8("backup_key"), length=32)`.  
**Encrypt backup:** AES-256-GCM. Nonce 12 random bytes. Wire format: `[12-byte nonce | ciphertext | GCM tag]`.  
**File extension:** `.dsbak`.

---

## 10. SECURITY LAYER

### 10.1 SecurePrefs

Backed by `flutter_secure_storage`.

```dart
// All reads/writes go through this singleton
class SecurePrefs {
  static final SecurePrefs _instance = SecurePrefs._();
  static SecurePrefs get instance => _instance;
  
  // Returns null on first-time failure — do NOT throw
  Future<String?> get(String key);
  Future<void> set(String key, String value);
  Future<void> remove(String key);
  Future<void> clearAll();
}
```

Keys used (exact strings):

| Key                          | Value description                          |
|------------------------------|--------------------------------------------|
| `app_pin_hash_<uid>`         | `hexSalt:hexHash` of app PIN               |
| `duress_pin_hash_<uid>`      | `hexSalt:hexHash` of duress PIN            |
| `signal_prekey_next_id`      | Integer as string, next PreKey ID to use   |
| `signal_signed_prekey_prev`  | Base64 serialized previous SPK             |
| `signal_signed_prekey_current`| Base64 serialized current SPK             |
| `turn_username`              | Cloudflare TURN username                   |
| `turn_credential`            | Cloudflare TURN credential                 |
| `turn_fetched_at`            | Unix millis as string                      |
| `background_ts`              | Unix millis when app last went to background|
| `signed_out_reason_inactivity`| "true" if auto-signed-out                 |
| `duress_wipe_in_progress`    | "true" during duress wipe                  |
| `safety_num_changed_<uid>`   | "true" if partner identity key changed     |
| `is_paired`                  | "true" after pairing                       |
| `conversation_id`            | Active conversation ID                     |
| `partner_uid`                | Active partner UID                         |

### 10.2 AppLockManager

**State:** Singleton with `AtomicInteger`-equivalent using a `ValueNotifier<int>`.

```
activeScreenCount : int  (screens currently in foreground)
backgroundTs      : int? (millis when count went to 0)
lockScreenActive  : bool (static, prevents double-lock)
AUTO_SIGNOUT_MS   : 15 * 60 * 1000  (15 minutes)
LOCK_DELAY_MS     : 30 * 1000       (30 seconds)
```

**Lifecycle hooks — call from every screen's `initState`/`dispose`:**
```dart
void onScreenStarted() {
  activeScreenCount++;
  // Do NOT clear backgroundTs here
}

void onScreenStopped() {
  activeScreenCount--;
  if (activeScreenCount == 0) {
    backgroundTs = DateTime.now().millisecondsSinceEpoch;
    SecurePrefs.instance.set('background_ts', backgroundTs.toString());
  }
}
```

**shouldLock():**
```dart
bool shouldLock() {
  if (lockScreenActive) return false;
  if (backgroundTs == null) return false;
  final elapsed = now - backgroundTs!;
  return elapsed > LOCK_DELAY_MS;
}
```

**shouldAutoSignOut():**
```dart
bool shouldAutoSignOut() {
  if (backgroundTs == null) return false;
  return (now - backgroundTs!) > AUTO_SIGNOUT_MS;
}
```

**BaseScreen mixin — every screen except Sign In, Display Name, Restore From Seed, Seed Phrase Display must apply this:**
```dart
@override
void initState() {
  super.initState();
  AppLockManager.instance.onScreenStarted();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (AppLockManager.instance.shouldAutoSignOut()) {
      _doAutoSignOut();
    } else if (AppLockManager.instance.shouldLock()) {
      _navigateToLockScreen();
    } else {
      AppLockManager.instance.clearBackgroundTs();
    }
  });
}

@override
void dispose() {
  AppLockManager.instance.onScreenStopped();
  super.dispose();
}
```

**Auto sign-out clears:** `is_paired`, `conversation_id`, `partner_uid`, `ecdh_shared_key`, `disappear_ms` from SecurePrefs.

### 10.3 DuressManager

**On duress PIN entered:**
1. Set `duress_wipe_in_progress = "true"` in SecurePrefs (commit first, before anything else).
2. Sign out of Firebase.
3. Call `db.clearAll()` — delete all local database rows.
4. Call `SecurePrefs.instance.clearAll()`.
5. Navigate to `SignInScreen` with `clearStack: true`.

**SignInScreen and SplashScreen must check:**
```dart
final wipe = await SecurePrefs.instance.get('duress_wipe_in_progress');
if (wipe == 'true') {
  await SecurePrefs.instance.remove('duress_wipe_in_progress');
  // Proceed normally (wipe already done)
}
```

---

## 11. FIREBASE / FIRESTORE

### 11.1 Collections and Documents

**`users/{uid}`**
```json
{
  "displayName": "string",
  "userId": "XXXXX-XXXXX-XXX",
  "online": true,
  "lastSeen": 1720000000000,
  "fcmToken": "string",
  "oneSignalId": "string"
}
```

**`identities/{userId}`** — keyed by DuoShield ID (not Firebase UID)
```json
{
  "uid": "firebase_uid",
  "identityKey": "base64_curve25519_public",
  "signedPreKey": { "id": 1, "publicKey": "base64", "signature": "base64" },
  "preKeys": [{ "id": 1, "publicKey": "base64" }]
}
```

**`chats/{chatId}`**
```json
{
  "participants": ["uid1", "uid2"],
  "createdAt": 1720000000000,
  "muted_uid1": false,
  "muted_uid2": false,
  "disappearMs": null,
  "lastMessage": "string ≤80 chars",
  "lastMessageTs": 1720000000000
}
```

**`chats/{chatId}/messages/{messageId}`**
```json
{
  "id": "messageId",
  "senderId": "uid",
  "ciphertext": "base64",
  "sigType": 1,
  "timestamp": 1720000000000,
  "status": "sent",
  "deletedForAll": false,
  "replyToId": null,
  "reactions": { "uid1": "❤️" },
  "edited": false,
  "editedCiphertext": null,
  "mediaType": null,
  "path": null,
  "mediaKey": null,
  "type": "text",
  "disappearMs": null,
  "linkPreviewUrl": null,
  "linkPreviewTitle": null,
  "linkPreviewImage": null
}
```

**`groups/{groupId}`**
```json
{
  "name": "string",
  "avatarUrl": null,
  "createdBy": "uid",
  "createdAt": 1720000000000,
  "members": ["uid1", "uid2"],
  "lastMessage": "string",
  "lastMessageTs": 1720000000000
}
```

**`groups/{groupId}/keys/{memberUid}`**
```json
{ "encryptedKey": "base64" }
```

**`groups/{groupId}/messages/{messageId}`** — same schema as chat messages.

**`calls/{callId}`**
```json
{
  "callerId": "uid",
  "calleeId": "uid",
  "type": "audio" | "video",
  "status": "ringing" | "accepted" | "ended" | "declined" | "missed",
  "offer": "sdp string",
  "answer": "sdp string",
  "callerCandidates": ["sdp candidate strings"],
  "calleeCandidates": ["sdp candidate strings"],
  "startedAt": 1720000000000
}
```

**`calls/{callId}/chat/{msgId}`**
```json
{
  "senderId": "uid",
  "text": "string",
  "timestamp": 1720000000000
}
```

### 11.2 Firestore Rules (do not modify, for reference)

- `users/{uid}`: read = any authenticated; write = owner only.
- `identities/{userId}`: read = any authenticated; write = owner (by uid match).
- `chats/{chatId}`: read/write = participants array contains request.auth.uid.
- `chats/{chatId}/messages`: read/write = parent chat participants.
- `groups/{groupId}`: read = members array contains uid; write = members.
- `groups/{groupId}/keys/{memberUid}`: write = creator or server.
- `calls/{callId}`: read/write = callerId or calleeId.
- `calls/{callId}/chat`: read/write = callerId or calleeId (from parent doc).

### 11.3 Realtime Listeners — One Per Screen

Each screen that listens to Firestore must:
1. Store the subscription in a `StreamSubscription` field.
2. Cancel in `dispose()`.
3. Never start more than one listener of the same type (check for existing before adding).

---

## 12. PUSH SERVER API

**Base URL:** `https://duoshield.onrender.com` (hardcoded in `constants.dart`)  
**Auth header:** `Authorization: Bearer <Firebase ID token>` on all routes.  
**Content-Type:** `application/json` on all POST requests.

### POST /mintToken
Request: `{ "uid": "string", "secret": "AUTH_SECRET from BuildConfig" }`  
Response: `{ "token": "firebase_custom_token" }`  
On error: throw `Exception("mintToken failed: ${response.statusCode}")`

### POST /createChat
Request: `{ "myUid": "string", "partnerUid": "string" }`  
Response: `{ "chatId": "string" }`  
On error: throw `Exception("createChat failed")`

### POST /migrateUid
Request: `{ "oldUid": "string", "newUid": "string" }`  
Response: `{ "success": true }`

### POST /turnCredentials
Request: `{}` (auth header required)  
Response: `{ "username": "string", "credential": "string", "ttl": 86400 }`  
Cache in SecurePrefs: store `turn_username`, `turn_credential`, `turn_fetched_at`.  
Refresh if `now - turn_fetched_at > 23 * 3600 * 1000` (23 hours).

### POST /b2PresignedPut
Request: `{ "key": "filename", "contentType": "image/jpeg" }`  
Response: `{ "url": "presigned S3 PUT URL", "objectKey": "string" }`

### POST /b2PresignedGet
Request: `{ "key": "objectKey" }`  
Response: `{ "url": "presigned GET URL" }`

### POST /b2Delete
Request: `{ "key": "objectKey" }`  
Response: `{ "success": true }`

### POST /linkPreview
Request: `{ "url": "https://..." }`  
Response: `{ "title": "string", "image": "url or null", "description": "string" }`

### POST /removeGroupMember
Request: `{ "groupId": "string", "memberUid": "string" }`  
Response: `{ "success": true }`

---

## 13. B2 STORAGE

**Media path format:** `b2:<objectKey>` stored in message `mediaUrl` field.  
**Object key format:** `<chatId>/<messageId>_<filename>`  
**Encryption:** AES-256-GCM, 12-byte random nonce prepended.  
**Wire format:** `[12-byte nonce | ciphertext | 16-byte GCM tag]`  
**Media key:** 32 random bytes → Base64 → stored in Firestore message `mediaKey` field.

**Upload flow:**
1. Generate 32-byte random `mediaKey`.
2. Encrypt file bytes: `AES-256-GCM(key=mediaKey, nonce=random12, plaintext=fileBytes)`.
3. Call `/b2PresignedPut` to get signed URL.
4. HTTP PUT encrypted bytes to signed URL.
5. Store `mediaKey` (Base64) and `b2:<objectKey>` in Firestore message.

**Download flow:**
1. Read `mediaKey` from Firestore message.
2. Read `mediaUrl` (strip `b2:` prefix → objectKey).
3. Call `/b2PresignedGet` to get signed GET URL.
4. HTTP GET encrypted bytes from signed URL.
5. Decrypt: `AES-256-GCM(key=base64Decode(mediaKey), ciphertext=bytes)`.
6. Cache decrypted bytes in local file cache.

**Delete flow:**
1. Call `/b2Delete` with objectKey.
2. Remove `mediaUrl` and `mediaKey` from Firestore message.

---

## 14. SCREEN: SPLASH

**File:** `lib/screens/splash/splash_screen.dart`  
**Route:** `/` (initial route)  
**Extends:** StatefulWidget (does NOT apply BaseScreen mixin — no auth check here)

### Layout
```
Background: colorBackground (#191620) full screen
Stack children (Z order bottom to top):
  1. MatrixRainView — fills entire screen
  2. Center child: Column(mainAxisSize: MainAxisSize.min)
       - Image.asset('assets/images/logo.png', width:120, height:120)
       - SizedBox(height:24)
       - Text('DuoShield', style: TextStyle(fontSize:28, fontWeight:FontWeight.bold, color:colorAccent, fontFamily:'Inter'))
       - SizedBox(height:8)
       - Text('Encrypted Messaging', style: TextStyle(fontSize:14, color:colorTextSecondary, fontFamily:'Inter'))
```

### Logic
1. On `initState`: add Firebase `AuthStateChanges` listener.
2. Wait 2000ms minimum (for animation).
3. After 2000ms, in `AuthStateChanges` callback:
   - If `duress_wipe_in_progress == "true"` in SecurePrefs → remove that key → navigate to `/sign-in` with `clearStack: true`.
   - If user is null → navigate to `/sign-in` with `clearStack: true`.
   - If user is not null:
     - Check `AppLockManager.shouldLock()`.
     - If true → navigate to `/lock` with `clearStack: true`.
     - If false → navigate to `/conversations` with `clearStack: true`.
4. Show no loading indicator. The matrix rain plays during the wait.

### MatrixRainView config on splash:
- Glyph color: `colorAccent` with opacity 0.4.
- Background: transparent (screen background shows through).
- Speed: 60ms per frame tick.

---

## 15. SCREEN: SIGN IN

**File:** `lib/screens/auth/sign_in_screen.dart`  
**Route:** `/sign-in`  
**Extends:** StatefulWidget — **NO** BaseScreen mixin.

### Layout
```
Scaffold(backgroundColor: colorBackground)
Body: Stack
  Layer 1: MatrixRainView (full screen, opacity 0.3)
  Layer 2: SafeArea → Column
    Expanded(flex:2): Center
      Column(mainAxisSize: min)
        Image.asset('assets/images/logo.png', width:88, height:88)
        SizedBox(height:16)
        Text('DuoShield', fontSize:28, bold, colorTextPrimary)
        SizedBox(height:6)
        Text('Private. Secure. Yours.', fontSize:14, colorTextSecondary)
    
    Expanded(flex:1): Column
      Padding(horizontal:24)
        DSButton(
          id: 'btnCreate'
          text: 'Create New Account'
          gradient: true
          height: 52
          onTap: → navigate to /display-name
        )
        SizedBox(height:14)
        OutlinedButton(
          id: 'btnRestore'
          text: 'Restore from Seed Phrase'
          height: 52
          style: border=colorAccent, textColor=colorAccent
          onTap: → navigate to /restore-from-seed
        )
        SizedBox(height:20)
        Text(
          'By continuing, you agree to our Terms of Service',
          fontSize:11, colorTextMuted, textAlign:center
        )
        SizedBox(height:24)
```

### Logic
1. On `initState`:
   - Check SecurePrefs `signed_out_reason_inactivity`.
   - If `"true"`: remove the key, show `SnackBar` with message: `"You were signed out due to inactivity"`, duration 3 seconds.
2. No Firebase calls on this screen.
3. `btnCreate` is ALWAYS enabled.
4. `btnRestore` is ALWAYS enabled.

---

## 16. SCREEN: DISPLAY NAME

**File:** `lib/screens/auth/display_name_screen.dart`  
**Route:** `/display-name`  
**Extends:** StatefulWidget — NO BaseScreen mixin.

### Layout
```
Scaffold(backgroundColor: colorBackground)
AppBar: transparent, no title, leading back arrow (colorTextPrimary)
Body: SafeArea → Padding(24) → Column
  SizedBox(height:32)
  Text('Choose a Display Name', fontSize:22, bold, colorTextPrimary)
  SizedBox(height:8)
  Text('This is how others will see you.', fontSize:14, colorTextSecondary)
  SizedBox(height:32)
  DSTextField(
    id: 'etDisplayName'
    hint: 'Your name'
    maxLength: 32
    textInputAction: TextInputAction.done
    onChanged: → clear tvError
  )
  SizedBox(height:8)
  Text(
    id: 'tvError'
    text: ''  [hidden when empty]
    fontSize:13, colorError
  )
  Spacer()
  DSButton(
    id: 'btnContinue'
    text: 'Continue'
    gradient: true
    enabled: etDisplayName.text.trim().isNotEmpty
    onTap: → _proceed()
  )
  SizedBox(height:24)
```

### TextWatcher equivalent:
- Listen to `etDisplayName` controller changes.
- If `text.trim().isEmpty` → disable `btnContinue`.
- Else → enable `btnContinue`.

### _proceed() logic:
1. Trim display name. If empty → set `tvError = "Please enter a display name"`, return.
2. Show `CircularProgressIndicator` overlay (full-screen, semi-transparent black).
3. Call `SeedPhraseHelper.generateMnemonic()` → 12-word mnemonic.
4. Call `SeedPhraseHelper.deriveUserId(mnemonic)` → userId.
5. Call `SeedPhraseHelper.deriveIdentityKey(mnemonic)` → identityKeyBytes.
6. Call `/mintToken` with derived userId → Firebase custom token.
7. Call `FirebaseAuth.signInWithCustomToken(token)`.
8. On success: navigate to `/seed-phrase-display` passing:
   - `mnemonic`: the 12-word string
   - `displayName`: trimmed name
   - `identityKey`: base64-encoded identity key bytes
   - `userId`: the XXXXX-XXXXX-XXX string
9. On failure: hide overlay, set `tvError = "Sign-in failed. Please try again."`.
10. Timeout after 30s: hide overlay, set `tvError = "Timed out. Check your connection."`.

---

## 17. SCREEN: SEED PHRASE DISPLAY

**File:** `lib/screens/auth/seed_phrase_display_screen.dart`  
**Route:** `/seed-phrase-display`  
**Receives:** `mnemonic`, `displayName`, `identityKey`, `userId` as route params  
**Extends:** StatefulWidget — NO BaseScreen mixin.

### Layout
```
Scaffold(backgroundColor: colorBackground)
AppBar: transparent, back arrow
Body: SafeArea → Column
  Padding(horizontal:24)
    Text('Your Recovery Phrase', fontSize:22, bold, colorTextPrimary)
    SizedBox(height:8)
    Text(
      'Write down these 12 words in order and keep them safe.\nAnyone with these words can access your account.',
      fontSize:13, colorTextSecondary
    )
    SizedBox(height:24)
    
    // gridWords: 4×3 grid of word tiles
    GridView.count(
      shrinkWrap: true
      crossAxisCount: 3
      childAspectRatio: 2.2
      crossAxisSpacing: 8
      mainAxisSpacing: 8
      children: [for each word] _WordTile(index+1, word)
    )
    // Each _WordTile:
    //   Container(color: colorSurface, borderRadius:8, padding:8)
    //   Row: Text('#N', fontSize:10, colorTextMuted) + SizedBox(4) + Text(word, bold)
    
    SizedBox(height:24)
    
    Row children:
      // btnCopyPhrase
      Expanded: OutlinedButton(
        text: 'Copy'
        icon: Icons.copy_outlined
        borderColor: colorAccent
        textColor: colorAccent
        onTap: → Clipboard.setData(mnemonic) → show SnackBar 'Copied to clipboard'
      )
      SizedBox(width:12)
      // btnViewQr
      Expanded: OutlinedButton(
        text: 'Show QR'
        icon: Icons.qr_code_outlined
        borderColor: colorAccent
        textColor: colorAccent
        onTap: → _showMnemonicQrDialog()
      )
    
    SizedBox(height:20)
    
    // cbSaved checkbox row
    Row:
      Checkbox(
        value: _cbSavedChecked
        onChanged: (v) { setState(() { _cbSavedChecked = v!; }) }
        activeColor: colorAccent
      )
      Expanded: GestureDetector(
        onTap: toggle checkbox
        child: Text("I've written down my recovery phrase", fontSize:13, colorTextPrimary)
      )
    
    SizedBox(height:16)
    
    // tvStep status text
    Text(_statusText, fontSize:12, colorTextMuted, textAlign:center)
    
    // progressSetup
    if (_loading) LinearProgressIndicator(color: colorAccent)
    
    SizedBox(height:16)
    
    DSButton(
      id: 'btnContinue'
      text: 'Continue'
      gradient: true
      enabled: _cbSavedChecked && !_loading
      onTap: → _deriveAndStore()
    )
    SizedBox(height:24)
```

### _showMnemonicQrDialog():
```
AlertDialog
  title: 'Scan to Restore'
  content: Center(child: QrImageView(data: mnemonic, size: 240))
  actions: [TextButton('Close' → Navigator.pop)]
```

### _deriveAndStore() logic (runs on button tap):
1. Set `_loading = true`, update `_statusText = "Registering identity..."`.
2. Write to Firestore `identities/{userId}` (merge): `{ "uid": firebaseUser.uid }`.
3. Update `_statusText = "Saving profile..."`.
4. Write to Firestore `users/{firebaseUser.uid}` (merge): `{ "displayName": displayName, "userId": userId }`.
5. Update `_statusText = "Setting up encryption..."`.
6. Generate Signal PreKey bundle:
   - Generate identity key pair (from `identityKey` bytes passed in).
   - Generate signed PreKey (ID=1).
   - Generate 25 one-time PreKeys (IDs 1–25).
   - Set `signal_prekey_next_id = "26"` in SecurePrefs.
7. Upload PreKey bundle to Firestore `identities/{userId}` (merge): `{ identityKey, signedPreKey, preKeys }`.
8. On success: set `_statusText = "Done!"`, navigate to `/conversations` with `clearStack: true`, pass `accountCreated: true`.
9. On failure: set `_loading = false`, `_statusText = ""`, show SnackBar `"Could not upload your keys. Please try again."`.

---

## 18. SCREEN: RESTORE FROM SEED

**File:** `lib/screens/auth/restore_from_seed_screen.dart`  
**Route:** `/restore-from-seed`  
**Extends:** StatefulWidget — NO BaseScreen mixin.

### Layout
```
Scaffold(backgroundColor: colorBackground)
AppBar: transparent, back arrow
Body: SafeArea → Padding(24) → Column
  Text('Restore Account', fontSize:22, bold, colorTextPrimary)
  SizedBox(height:8)
  Text('Enter your DuoShield ID and 12-word recovery phrase.', fontSize:13, colorTextSecondary)
  SizedBox(height:32)
  
  DSTextField(
    id: 'etAccountId'
    hint: 'Account ID (XXXXX-XXXXX-XXX)'
    maxLength: 17
    keyboardType: TextInputType.visiblePassword  // prevent auto-capitalize
    textCapitalization: TextCapitalization.characters
  )
  SizedBox(height:16)
  
  DSTextField(
    id: 'etSeedWords'
    hint: 'Enter 12 recovery words separated by spaces'
    maxLines: 4
    minLines: 3
    textInputAction: TextInputAction.newline
  )
  SizedBox(height:8)
  
  Text(
    id: 'tvError'
    text: _errorText  [hidden when empty]
    fontSize:13, colorError
  )
  
  SizedBox(height:8)
  Text(id:'tvStep', text:_stepText, fontSize:12, colorTextMuted)
  
  SizedBox(height:16)
  if (_loading) LinearProgressIndicator(color: colorAccent)
  
  Spacer()
  DSButton(
    id: 'btnRestore'
    text: 'Restore Account'
    gradient: true
    enabled: !_loading
    onTap: → _attemptRestore()
  )
  SizedBox(height:24)
```

### _attemptRestore() logic:
1. Trim both inputs. If either empty → set `_errorText = "Please fill in all fields."`, return.
2. Split `etSeedWords` by whitespace. Count words. If != 12 → set `_errorText = "Please enter exactly 12 words."`, return.
3. Validate each word against BIP39 list. If any invalid → `_errorText = "Invalid word: '<word>'. Please check your phrase."`, return.
4. Set `_loading = true`, `_stepText = "Validating phrase..."`.
5. Call `SeedPhraseHelper.deriveUserId(mnemonic)` → `derivedUserId`.
6. Compare `derivedUserId.toUpperCase()` to `etAccountId.text.trim().toUpperCase()`.
7. If mismatch → `_loading = false`, `_errorText = "Account ID does not match this recovery phrase."`, return.
8. `_stepText = "Signing in..."`.
9. Call `/mintToken` with derivedUserId → Firebase custom token.
10. Call `FirebaseAuth.signInWithCustomToken(token)`.
11. `_stepText = "Fetching account data..."`.
12. Read Firestore `identities/{derivedUserId}` → get `uid` field.
13. If `uid != firebaseUser.uid` → call `/migrateUid` with `oldUid=uid`, `newUid=firebaseUser.uid`.
14. `_stepText = "Restoring messages..."`.
15. Fetch all `chats` where `participants` arrayContains `firebaseUser.uid`.
16. For each chat, fetch messages subcollection, decrypt each, insert into local DB.
17. `_stepText = "Restoring contacts..."`.
18. Read Room contacts for those chat partners, insert into local DB.
19. `_stepText = "Done!"`.
20. Navigate to `/conversations` with `clearStack: true`.
21. On any failure: `_loading = false`, `_stepText = ""`, `_errorText = "Restore failed: <error message>"`.
22. Timeout 60s total: `_errorText = "Restore timed out. Check your connection."`.

---

## 19. SCREEN: CONVERSATION LIST

**File:** `lib/screens/conversations/conversation_list_screen.dart`  
**Route:** `/conversations`  
**Applies:** BaseScreen mixin.

### Layout
```
Scaffold(backgroundColor: colorBackground)
Body: Column
  // Top bar (not AppBar — custom)
  Container(color:colorSurface, height:56, padding:horizontal 16)
    Row:
      Text('DuoShield', fontSize:20, bold, colorTextPrimary)  [when search not active]
      OR
      DSTextField(id:'etSearch', hint:'Search...') [when search active]
      
      Spacer()
      
      // btn_search_toggle
      IconButton(icon: Icons.search, color:colorIconDefault, onTap: → _toggleSearch())
      [hidden when search active]
      
      // btn_close_search
      IconButton(icon: Icons.close, color:colorIconDefault, onTap: → _closeSearch())
      [hidden when search not active]
      
      // btn_call_history
      IconButton(icon: Icons.call_outlined, color:colorIconDefault, onTap: → /call-history)
      
      // btn_menu
      IconButton(icon: Icons.more_vert, color:colorIconDefault, onTap: → _showPopupMenu())
  
  // archived_banner — visible only if archivedCount > 0 and !showArchived
  GestureDetector(
    onTap: → _toggleArchive()
    child: Container(
      color: colorSurfaceVariant
      padding: 12 horizontal, 8 vertical
      child: Row:
        Icon(Icons.archive_outlined, colorTextSecondary, size:18)
        SizedBox(8)
        Text('Archived (N)', colorTextSecondary, fontSize:13)
        Spacer()
        Icon(Icons.chevron_right, colorTextMuted)
    )
  )
  
  // Shimmer loading state (visible until first Firestore data arrives)
  if (_loading) ShimmerList(itemCount:6, ...)
  
  // Empty state (visible when no conversations and not loading)
  if (!_loading && _conversations.isEmpty)
    Expanded: Center: Column:
      Icon(Icons.chat_bubble_outline, size:64, colorTextMuted)
      SizedBox(16)
      Text('No conversations yet', colorTextSecondary, fontSize:16)
      SizedBox(12)
      DSButton(
        id: 'btnEmptyAddContact'
        text: 'Add a Contact'
        gradient: true
        width: 160
        onTap: → /add-contact
      )
  
  // Conversation list
  if (!_loading && _conversations.isNotEmpty)
    Expanded: ListView.builder(
      itemCount: _conversations.length
      itemBuilder: → ConversationTile
    )

  // FAB
  FloatingActionButton(
    id: 'fabNewChat'
    backgroundColor: colorAccent
    child: Icon(Icons.edit_outlined, color: Colors.white)
    onPressed: → /add-contact
  )
```

### ConversationTile (per item):
```
GestureDetector(
  onTap: → navigate to /chat or /group-chat (based on type)
  onLongPress: → _showConversationOptions(conv)
  child: Dismissible(
    key: Key(conv.id)
    direction: DismissDirection.endToStart
    background: Container(color:colorError, child: Icon(Icons.archive, white))
    onDismissed: → archive conversation
    child: ListTile(
      contentPadding: horizontal 16, vertical 4
      leading: CircleAvatar(radius:26, backgroundColor:colorSurface,
                child: Text(initials, colorAccent, bold))  [or CachedNetworkImage if avatar]
      title: Text(conv.partnerName, colorTextPrimary, bold if unread)
      subtitle: Text(conv.lastMessage, colorTextSecondary, maxLines:1, overflow:ellipsis)
      trailing: Column:
        Text(formattedTime, colorTextMuted, fontSize:11)
        SizedBox(4)
        if unreadCount > 0:
          CircleAvatar(radius:10, backgroundColor:colorAccent,
            child: Text(unreadCount, white, fontSize:10))
        if conv.muted:
          Icon(Icons.volume_off, colorTextMuted, size:14)
    )
  )
)
```

### Popup Menu (btn_menu):
Items in exact order:
1. `New Chat` → /add-contact
2. `New Group` → /create-group
3. `Settings` → /settings
4. Divider
5. `Wipe & Exit` (colorError text) → _confirmWipeAndExit()

### Long-press Conversation Options (BottomSheet):
Items in exact order:
1. `Archive` / `Unarchive` (based on current state)
2. `Mute` / `Unmute`
3. `Delete` (colorError) → confirm dialog → delete from local DB and Firestore

### _confirmWipeAndExit():
```
AlertDialog:
  title: 'Wipe & Exit'
  content: 'This will erase all local data and sign out. This cannot be undone.'
  actions:
    TextButton('Cancel' → dismiss)
    TextButton('Wipe', style: colorError → _performWipe())
```

### Firestore Listener:
```dart
FirebaseFirestore.instance
  .collection('chats')
  .where('participants', arrayContains: myUid)
  .snapshots()
  .listen(_onChatsUpdated);
```

On each event:
- Update `lastMessage`, `lastMessageTs`, `muted_{myUid}` from Firestore doc.
- Merge with local DB contact display names.
- Sort by `lastMessageTs` descending.
- Filter: if `!showArchived` → exclude archived conversations.

### Search:
- Client-side filter of `_conversations` list by `partnerName.toLowerCase().contains(query)`.
- Update list in real-time as user types.

---

## 20. SCREEN: CHAT

**File:** `lib/screens/chat/chat_screen.dart`  
**Route:** `/chat/:conversationId`  
**Params:** `conversationId`, `partnerUid`  
**Applies:** BaseScreen mixin.

### Layout
```
Scaffold(backgroundColor: colorBackground)

// Top AppBar (custom)
Container(color: colorSurface, height:56)
  Row:
    IconButton(Icons.arrow_back → Navigator.pop)
    CircleAvatar(radius:18, ...) [partner avatar or initials]
    SizedBox(8)
    Column:
      Text(partnerName, bold, colorTextPrimary, fontSize:15)
      Text(_partnerStatus, fontSize:11, colorTextSecondary)  [Online / Last seen ...]
    Spacer()
    // Timer button (disappearing messages)
    IconButton(Icons.timer_outlined, colorIconDefault, onTap:→_showDisappearDialog())
    // Safety numbers button
    IconButton(Icons.security_outlined, colorIconDefault, onTap:→/safety-numbers)
    // More menu
    IconButton(Icons.more_vert, onTap:→_showChatMenu())

// Safety number banner (shown when safety_num_changed_<partnerUid> == "true")
Container(color: colorWarning.withOpacity(0.15), padding:12)
  Row:
    Icon(Icons.warning_amber, colorWarning, size:18)
    SizedBox(8)
    Expanded: Text("Security codes changed. Verify your contact.", colorWarning, fontSize:12)
    TextButton('Verify' → /safety-numbers)
    IconButton(Icons.close → _hideSafetyBanner())

// Messages list
Expanded: ListView.builder(
  reverse: true  // newest at bottom
  padding: EdgeInsets.symmetric(horizontal:12, vertical:8)
  itemCount: _messages.length
  itemBuilder: → MessageBubble(message, isMe: message.senderId == myUid)
)

// Typing indicator (shown when partner is typing)
if (_partnerTyping)
  Padding(12): TypingDotsView()

// Reply bar (shown when replyToMessage != null)
if (_replyTo != null)
  Container(color:colorSurfaceVariant, padding:8)
    Row:
      Container(width:3, color:colorAccent)
      SizedBox(8)
      Expanded: Column:
        Text(replyTo.senderName, colorAccent, fontSize:12, bold)
        Text(replyTo.text, colorTextSecondary, fontSize:12, maxLines:1)
      IconButton(Icons.close → setState(_replyTo = null))

// Input bar
Container(color:colorSurface, padding:horizontal 8, vertical 6)
  Row:
    // Attachment button
    IconButton(Icons.attach_file, colorIconDefault, onTap:→_showAttachmentMenu())
    // Text field
    Expanded: DSTextField(
      id: 'etMessage'
      hint: 'Message'
      maxLines: 6
      minLines: 1
      onChanged: → _onTypingChanged()
    )
    // Voice note button (when text is empty)
    if etMessage.text.isEmpty:
      GestureDetector(
        onLongPressStart: → _startVoiceRecord()
        onLongPressEnd: → _stopAndSendVoiceNote()
        child: IconButton(Icons.mic, colorAccent)
      )
    // Send button (when text is not empty)
    if etMessage.text.isNotEmpty:
      IconButton(
        icon: Icon(Icons.send, colorAccent)
        onPressed: → _sendMessage()
        [disabled after tap until Firestore ack → re-enabled]
      )
```

### _sendMessage() logic:
1. Disable send button immediately.
2. Get plaintext = `etMessage.text.trim()`. If empty, return.
3. Clear `etMessage` text field.
4. Generate `messageId = UUID v4`.
5. Insert optimistic message in local list with status `"sending"`.
6. Call `SignalCipherHelper.encrypt(partnerUid, utf8.encode(plaintext))` → ciphertext bytes.
7. Build Firestore message doc:
   ```json
   {
     "id": messageId,
     "senderId": myUid,
     "ciphertext": base64(ciphertext),
     "sigType": sigType,
     "timestamp": serverTimestamp(),
     "status": "sent",
     "deletedForAll": false,
     "type": "text",
     "replyToId": replyTo?.id
   }
   ```
8. Write to `chats/{conversationId}/messages/{messageId}`.
9. Write to `chats/{conversationId}`: `{ lastMessage: plaintext.substring(0,80), lastMessageTs: now }`.
10. On success: update local message status to `"sent"`, re-enable send button.
11. On failure: re-enable send button, show SnackBar `"Failed to send message"`, keep message in list with error indicator.

### Firestore Message Listener:
```dart
FirebaseFirestore.instance
  .collection('chats').doc(conversationId)
  .collection('messages')
  .orderBy('timestamp', descending: false)
  .startAfter([latestKnownTimestamp])
  .snapshots()
  .listen(_onMessagesUpdate)
```

On ADDED events:
- Decrypt ciphertext with SignalCipherHelper.
- If decrypt fails → store text as `"[Message could not be decrypted]"`.
- If sigType == 0 → store text as `"[Legacy message — not decryptable]"`.
- Check knownIds HashSet to prevent duplicates.
- Insert into local DB.
- If sender != myUid → send delivery receipt.

On MODIFIED events:
- If `deletedForAll == true` → remove message from list + local DB.
- If `reactions` changed → update bubble reactions.
- If `edited == true` → decrypt `editedCiphertext` → update bubble text.
- If `status` changed → update status icon (but never downgrade "read" → "delivered").

### Long-press Message → Action Sheet:
Show `BottomSheetDialog` (colorSurface background, rounded top corners 16dp):

**Emoji reaction row** (6 emojis, tappable):
`❤️` `😂` `😮` `😢` `👍` `👎`
On tap: write `reactions.{myUid} = emoji` to Firestore doc. Dismiss sheet.

**Action items** (exact order, exact labels):

| Icon                    | Label              | Action                                      |
|-------------------------|--------------------|---------------------------------------------|
| Icons.reply             | Reply              | Set `_replyTo = message`, dismiss sheet     |
| Icons.copy              | Copy               | Clipboard.setData(message.text)             |
| Icons.edit              | Edit               | [only for own messages] show edit dialog    |
| Icons.forward           | Forward            | show contact picker → encrypt → send        |
| Icons.star_border       | Star               | toggle starred in Room + Firestore          |
| Icons.push_pin_outlined | Pin                | toggle pinned in Room + Firestore           |
| Icons.delete_outline    | Delete locally     | colorError — remove from adapter + Room only|
| Icons.delete_forever    | Delete for everyone| colorError — write deletedForAll:true to Firestore |

**Edit Dialog:**
```
AlertDialog:
  title: 'Edit Message'
  content: TextField(controller: pre-filled with current text, maxLines:null)
  actions:
    TextButton('Cancel')
    TextButton('Save' → _saveEdit())
```
`_saveEdit()`: encrypt new text → write `editedCiphertext: base64`, `edited: true` to Firestore → update local Room.

### Disappear Timer Dialog:
```
AlertDialog:
  title: 'Disappearing Messages'
  content: Column with RadioListTile options:
    ○ Off
    ○ 30 seconds
    ○ 5 minutes
    ○ 1 hour
    ○ 24 hours
    ○ 7 days
  actions:
    TextButton('Cancel')
    TextButton('Set' → write disappearMs to Firestore chats/{id})
```

### Chat Menu (more_vert):
Items:
1. `Search in chat` → show search bar in top bar
2. `Clear chat locally` → confirm → delete all local messages for this chat
3. `Export chat` → generate txt file and share via Share sheet

### Attachment Menu (BottomSheet):
```
Options (4 items, 2×2 grid):
  📷 Camera    → ImagePicker(ImageSource.camera) → _sendMedia('image')
  🖼 Gallery   → ImagePicker(ImageSource.gallery) → _sendMedia
  🎵 Audio     → FilePicker(FileType.audio) → _sendMedia('audio')
  📄 File      → FilePicker(FileType.any) → _sendMedia('file')
```

### _sendMedia(type) logic:
1. Encrypt file with AES-256-GCM using random 32-byte key.
2. Call `/b2PresignedPut` → signed URL.
3. HTTP PUT encrypted bytes.
4. Build Firestore message with `path: "b2:<objectKey>"`, `mediaType: type`, `mediaKey: base64(key)`, `type: "media"`.

### Delivery Receipts:
- When chat screen is open and new message arrives from partner: write `status: "read"` to Firestore message doc.
- When app receives FCM with type `"ack"` containing `chatId` + `messageId` + `status: "delivered"`: update local message status.
- Status update rule: never write "delivered" if current status is "read". Never write "sent" if current is "delivered" or "read".

### Typing Indicator:
- On text change: write `typing_{myUid}: true` to `chats/{conversationId}` doc. Start 3s timer; on timeout write `false`.
- Listen to `typing_{partnerUid}` field in chats doc; update `_partnerTyping` state.

### Presence:
- On chat open: read `users/{partnerUid}` `online` field + `lastSeen` field → display in subtitle.
- Listen to `users/{partnerUid}` snapshots while screen is open.

---

## 21. SCREEN: GROUP CHAT

**File:** `lib/screens/group_chat/group_chat_screen.dart`  
**Route:** `/group-chat/:groupId`  
**Applies:** BaseScreen mixin.

### Layout
Same structure as Chat screen with these differences:
- AppBar title = group name.
- Subtitle = member count: `N members`.
- No safety number banner.
- No disappear timer button.
- Message bubbles show sender name above bubble (colorAccent, fontSize:11) for messages not from me.
- No delivery/read receipts.

### Firestore Listener:
```dart
FirebaseFirestore.instance
  .collection('groups').doc(groupId)
  .collection('messages')
  .orderBy('timestamp')
  .startAfter([latestTs])
  .snapshots()
```

### Encrypt/Decrypt:
- Fetch group key from `groups/{groupId}/keys/{myUid}` → `encryptedKey` → Signal-decrypt → 32-byte AES key.
- Encrypt message: `GroupCryptoHelper.encryptGroup(groupKey, utf8.encode(plaintext))`.
- Decrypt: `GroupCryptoHelper.decryptGroup(groupKey, base64Decode(ciphertext))`.

### Group Menu (more_vert):
1. `Group Info` → show member list BottomSheet
2. `Add Member` → contact picker
3. `Leave Group` → confirm → call `/removeGroupMember` with myUid → remove from local DB

### Member List BottomSheet:
```
ListView of members, each row:
  CircleAvatar + displayName + (if creator: Text 'Admin', colorAccent, fontSize:10)
  if myUid == createdBy:
    trailing: IconButton(Icons.person_remove → confirm → removeGroupMember)
```

---

## 22. SCREEN: CREATE GROUP

**File:** `lib/screens/create_group/create_group_screen.dart`  
**Route:** `/create-group`  
**Applies:** BaseScreen mixin.

### Layout
```
Scaffold(backgroundColor: colorBackground)
AppBar: title 'New Group', leading back arrow
Body: Column
  // Group avatar (optional)
  GestureDetector(
    onTap: → ImagePicker(gallery) to pick avatar
    child: CircleAvatar(radius:44, backgroundColor:colorSurface,
      child: if no avatar: Icon(Icons.camera_alt, colorTextMuted)
      else: CachedNetworkImage(avatar)
    )
  )
  SizedBox(16)
  
  // Group name field
  DSTextField(hint:'Group Name', maxLength:64, id:'etGroupName')
  SizedBox(24)
  
  Text('Select Members', bold, colorTextPrimary)
  SizedBox(8)
  
  // Contact list with checkboxes
  Expanded: ListView.builder(
    itemBuilder: → CheckboxListTile(
      title: Text(contact.displayName)
      subtitle: Text(contact.userId, fontSize:11)
      value: _selectedUids.contains(uid)
      activeColor: colorAccent
      onChanged: → toggle uid in _selectedUids
    )
  )
  
  // Create button
  Padding(16): DSButton(
    text: 'Create Group (N selected)'
    gradient: true
    enabled: etGroupName.trim().isNotEmpty && _selectedUids.length >= 2
    onTap: → _createGroup()
  )
```

### _createGroup() logic:
1. Validate: name not empty, at least 2 members selected (excluding self).
2. Generate `groupId = UUID v4`.
3. Generate `groupKey = 32 random bytes`.
4. Add `myUid` to members list.
5. For each member (including self): Signal-encrypt `groupKey` for that member → store in Firestore `groups/{groupId}/keys/{memberUid}`.
6. Write Firestore `groups/{groupId}`:
   ```json
   {
     "name": groupName,
     "createdBy": myUid,
     "createdAt": serverTimestamp(),
     "members": [myUid, ...selectedUids]
   }
   ```
7. Insert group into local Room DB.
8. Insert each member into `group_members` table.
9. Navigate to `/group-chat/{groupId}` with `clearStack: false`.

---

## 23. SCREEN: ADD CONTACT

**File:** `lib/screens/add_contact/add_contact_screen.dart`  
**Route:** `/add-contact`  
**Applies:** BaseScreen mixin.

### Layout
```
Scaffold(backgroundColor: colorBackground)
AppBar: title 'Add Contact'
Body: DefaultTabController(length:3)
  TabBar:
    Tab('Enter ID')
    Tab('Scan QR')
    Tab('Paste Link')
  
  TabBarView:
    // Tab 0: Enter ID
    Padding(24): Column:
      DSTextField(
        id: 'etContactId'
        hint: 'XXXXX-XXXXX-XXX'
        maxLength: 17
        textCapitalization: TextCapitalization.characters
      )
      SizedBox(16)
      DSButton(text:'Add Contact', gradient:true, onTap:→_addByUserId())
    
    // Tab 1: Scan QR
    Expanded: MobileScanner(
      onDetect: (capture) {
        final code = capture.barcodes.first.rawValue;
        if (code.startsWith('duoshield://add/')) {
          _addByUserId(code.replaceFirst('duoshield://add/', ''))
        }
      }
    )
    
    // Tab 2: Paste / Share Link
    Padding(24): Column:
      Text('Share your DuoShield ID', colorTextSecondary)
      SizedBox(16)
      Container(color:colorSurface, padding:16, borderRadius:12):
        SelectableText(myUserId, style:monospace-like, colorAccent)
      SizedBox(16)
      Row:
        Expanded: OutlinedButton('Copy', icon:Icons.copy → Clipboard.setData('duoshield://add/$myUserId'))
        SizedBox(8)
        Expanded: OutlinedButton('Share', icon:Icons.share → Share.share('duoshield://add/$myUserId'))
```

### _addByUserId(userId) logic:
1. Validate format: matches regex `^[A-Z2-9]{5}-[A-Z2-9]{5}-[A-Z2-9]{3}$`.
2. If invalid → show SnackBar `"Invalid DuoShield ID format"`.
3. Show loading overlay.
4. Read Firestore `identities/{userId}` → get `uid` field.
5. If not found → SnackBar `"User not found"`, dismiss overlay, return.
6. If found:
   - Call `/createChat` with `myUid` and partner `uid` → `chatId`.
   - Read Firestore `users/{partnerUid}` → `displayName`.
   - Insert contact into local Room DB.
   - Insert conversation into local Room DB.
   - Navigate to `/chat/{chatId}` with `partnerUid`.
7. Dismiss loading overlay.

---

## 24. SCREEN: CONTACT DETAIL

**File:** `lib/screens/contact_detail/contact_detail_screen.dart`  
**Route:** `/contact-detail`  
**Params:** `partnerUid`, `partnerName`, `conversationId`  
**Applies:** BaseScreen mixin.

### Layout
```
Scaffold(backgroundColor: colorBackground)
AppBar: title partnerName
Body: Padding(24): Column
  Center: CircleAvatar(radius:52, ...)
  SizedBox(16)
  Center: Text(partnerName, fontSize:22, bold)
  Center: Text(partnerUserId, fontSize:13, colorTextSecondary)
  SizedBox(32)
  
  ListTile(leading:Icon(Icons.message), title:Text('Send Message'), onTap:→/chat)
  Divider(color:colorDivider)
  ListTile(leading:Icon(Icons.call), title:Text('Voice Call'), onTap:→_startCall(false))
  Divider(color:colorDivider)
  ListTile(leading:Icon(Icons.videocam), title:Text('Video Call'), onTap:→_startCall(true))
  Divider(color:colorDivider)
  ListTile(leading:Icon(Icons.security), title:Text('Verify Safety Numbers'), onTap:→/safety-numbers)
  Divider(color:colorDivider)
  ListTile(
    leading:Icon(Icons.block, colorError)
    title:Text('Block Contact', colorError)
    onTap:→_confirmBlock()
  )
  Divider(color:colorDivider)
  ListTile(
    leading:Icon(Icons.delete_outline, colorError)
    title:Text('Delete Contact', colorError)
    onTap:→_confirmDelete()
  )
```

---

## 25. SCREEN: CALL

**File:** `lib/screens/call/call_screen.dart`  
**Route:** `/call`  
**Params:** `partnerUid`, `partnerName`, `isVideo: bool`, `callId: String?` (null = outgoing, provided = incoming)  
**Applies:** BaseScreen mixin.

### Layout
```
Scaffold(backgroundColor: Colors.black)
Stack:
  // Remote video (full screen) — only for video call
  if isVideo: RTCVideoView(_remoteRenderer, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover)
  
  // Local video (PiP, bottom-right) — only for video call
  if isVideo:
    Positioned(right:16, bottom:120)
      Container(width:100, height:140, borderRadius:12, clipBehavior:Clip.hardEdge)
        RTCVideoView(_localRenderer)
  
  // Partner info (top center) — voice call or connecting state
  Positioned(top:80): Center: Column:
    CircleAvatar(radius:48, ...)
    SizedBox(16)
    Text(partnerName, white, fontSize:22, bold)
    SizedBox(8)
    Text(_callStatus, white, fontSize:14)  // 'Calling...' | 'Ringing...' | 'Connected' | '00:32'
  
  // Control buttons (bottom strip)
  Positioned(bottom:32): Container(width:screenWidth)
    Row(mainAxisAlignment:spaceEvenly):
      // btnMute
      _CallButton(icon: _muted ? Icons.mic_off : Icons.mic,
        label: _muted ? 'Unmute' : 'Mute',
        color: _muted ? colorError : Colors.white54,
        onTap: → _toggleMute())
      
      // btnEndCall
      _CallButton(icon: Icons.call_end,
        label: 'End',
        color: colorError,
        size: 72,
        onTap: → _endCall())
      
      // btnSpeaker (audio only) OR btnCamera (video only)
      if !isVideo:
        _CallButton(icon: _speakerOn ? Icons.volume_up : Icons.volume_off,
          label: 'Speaker', onTap: → _toggleSpeaker())
      if isVideo:
        _CallButton(icon: Icons.flip_camera_ios_outlined,
          label: 'Flip', onTap: → _flipCamera())
      
      // btnChat (in-call chat)
      _CallButton(icon: Icons.chat_bubble_outline,
        label: 'Chat', onTap: → _showInCallChat())
  
  // Incoming call UI (shown when callId provided and status == 'ringing')
  if _isIncoming && _status == 'ringing':
    Positioned(bottom:120): Row(spaceEvenly):
      _CallButton(icon:Icons.call_end, label:'Decline', color:colorError, onTap:→_declineCall())
      _CallButton(icon:Icons.call, label:'Accept', color:colorSuccess, size:72, onTap:→_acceptCall())
```

### Call flow — OUTGOING:
1. Fetch TURN credentials (from cache or `/turnCredentials`). Wait for result. Max 3s timeout.
2. Initialize `RTCPeerConnection` with ICE servers:
   ```dart
   {
     'iceServers': [
       {'urls': 'stun:stun.cloudflare.com:3478'},
       {
         'urls': turnUrl.split(','),  // comma-separated
         'username': turnUsername,
         'credential': turnCredential,
       }
     ],
     'iceTransportPolicy': 'all',  // NOT relay-only
   }
   ```
3. If video: call `getUserMedia({'video': true, 'audio': true})`.
4. If audio only: call `getUserMedia({'video': false, 'audio': true, 'echoCancellation': true, 'noiseSuppression': true, 'autoGainControl': true})`.
5. Add local tracks to peer connection.
6. Start local video renderer (if video).
7. Create Firestore doc `calls/{callId}` with `callerId=myUid, calleeId=partnerUid, type, status='ringing'`.
8. Create SDP offer: `peerConnection.createOffer()`.
9. Set local description.
10. Write offer SDP to Firestore `calls/{callId}` field `offer`.
11. Collect ICE candidates → write each to Firestore `calls/{callId}` field `callerCandidates` via `arrayUnion`.
12. Listen to `calls/{callId}` for `status` changes and `answer` field.
13. On `answer` received: set remote description.
14. On `calleeCandidates` received: add each ICE candidate.
15. Update `_callStatus` text from `"Calling..."` → `"Connected"` → start timer.

### Call flow — INCOMING:
1. Receive FCM with `type: "incoming_call"`, `callId`, `callerId`, `callerName`, `isVideo`.
2. Show incoming call notification (or CallScreen directly if app is foreground).
3. On `_acceptCall()`:
   - Fetch TURN credentials.
   - Init RTCPeerConnection + media same as above.
   - Init renderers BEFORE creating answer.
   - Read offer SDP from Firestore `calls/{callId}.offer`.
   - Set remote description with offer.
   - Create SDP answer. Set local description.
   - Write answer to Firestore `calls/{callId}.answer`.
   - Write callee ICE candidates to `calls/{callId}.calleeCandidates` via arrayUnion.
4. On `_declineCall()`:
   - Write `status: "declined"` to Firestore.
   - Navigate back.

### `onTrack` handler (CRITICAL — one-way audio bug fix):
```dart
peerConnection.onTrack = (RTCTrackEvent event) {
  if (event.streams.isNotEmpty) {
    _remoteRenderer.srcObject = event.streams[0];
    // MUST enable the track explicitly:
    event.track.enabled = true;
  }
};
```

### ICE restart on disconnect:
```dart
peerConnection.onIceConnectionState = (state) {
  if (state == RTCIceConnectionState.RTCIceConnectionStateDisconnected ||
      state == RTCIceConnectionState.RTCIceConnectionStateFailed) {
    peerConnection.restartIce();
  }
};
```

### _endCall():
1. Write `status: "ended"` to Firestore.
2. Stop local media tracks.
3. Close peer connection.
4. Dispose renderers.
5. Insert CallRecord into local DB.
6. Navigate back.

### dispose():
```dart
_localRenderer.dispose();
_remoteRenderer.dispose();
_localStream?.getTracks().forEach((t) => t.stop());
_peerConnection?.close();
```

### In-call Chat (BottomSheet):
```
DraggableScrollableSheet:
  Container(color:colorSurface):
    // Message list from calls/{callId}/chat subcollection
    // Input row: TextField + Send button
    // Send: write to calls/{callId}/chat/{uuid} { senderId, text, timestamp }
```

---

## 26. SCREEN: CALL HISTORY

**File:** `lib/screens/call_history/call_history_screen.dart`  
**Route:** `/call-history`  
**Applies:** BaseScreen mixin.

### Layout
```
Scaffold(backgroundColor: colorBackground)
AppBar: title 'Call History'
Body: StreamBuilder from local DB call_history table ordered by startedAt DESC
  ListView.builder:
    ListTile:
      leading: CircleAvatar(radius:22, ...) [partner initials]
      title: Text(partnerName, bold)
      subtitle: Row:
        Icon(direction=='outgoing' ? Icons.call_made : Icons.call_received, size:13,
             color: outcome=='missed' ? colorError : colorSuccess)
        SizedBox(4)
        Text('${directionLabel} · ${formattedDate}', fontSize:12, colorTextSecondary)
      trailing: Column:
        Icon(isVideo ? Icons.videocam_outlined : Icons.call_outlined, colorIconDefault)
        SizedBox(4)
        Text(formatDuration(durationSeconds), fontSize:11, colorTextMuted)
      onTap: → show call options BottomSheet
```

### Call options BottomSheet:
```
ListTile 'Call back (Audio)' → _startCall(false)
ListTile 'Call back (Video)' → _startCall(true)
ListTile 'Send Message' → /chat
ListTile 'Delete record' (colorError) → delete from local DB
```

---

## 27. SCREEN: LOCK SCREEN

**File:** `lib/screens/lock/lock_screen.dart`  
**Route:** `/lock`  
**Extends:** StatefulWidget — NO BaseScreen mixin.

### Layout
```
Scaffold(backgroundColor: colorBackground)
// Light-themed override for status bar icons
SafeArea: Center: Column:
  SizedBox(height:48)
  Image.asset('assets/images/logo.png', width:72)
  SizedBox(24)
  Text('DuoShield', fontSize:22, bold, colorTextPrimary)
  SizedBox(8)
  Text('Enter your PIN', fontSize:14, colorTextSecondary)
  SizedBox(32)
  
  // PIN dots display (4 dots)
  Row(mainAxisAlignment:center, spacing:16):
    [for i in 0..3] Container(
      width:16, height:16, borderRadius:8,
      color: i < _pinInput.length ? colorAccent : colorSurfaceVariant
    )
  
  SizedBox(32)
  
  // PIN pad (3×4 grid)
  // Row 1: 1, 2, 3
  // Row 2: 4, 5, 6
  // Row 3: 7, 8, 9
  // Row 4: [biometric icon], 0, [backspace icon]
  GridView.count(
    crossAxisCount: 3
    shrinkWrap: true
    childAspectRatio: 1.6
    children: [
      _PinKey('1'), _PinKey('2'), _PinKey('3'),
      _PinKey('4'), _PinKey('5'), _PinKey('6'),
      _PinKey('7'), _PinKey('8'), _PinKey('9'),
      _BiometricKey(), _PinKey('0'), _BackspaceKey()
    ]
  )
  
  SizedBox(24)
  
  // Error text
  if (_errorText != null)
    Text(_errorText!, colorError, fontSize:13)
  
  SizedBox(16)
  
  // Sign out link
  TextButton(
    'Sign out',
    style: colorTextMuted
    onTap: → _confirmSignOut()
  )
```

### _PinKey widget:
```
GestureDetector(
  onTap: → _onDigitTap(digit)
  child: Container(
    width:72, height:52, borderRadius:8
    color: colorSurface
    child: Center: Text(digit, fontSize:24, bold, colorTextPrimary)
  )
)
```

### _onDigitTap(digit) logic:
1. If `_pinInput.length < 4`: append digit.
2. If `_pinInput.length == 4`: call `_verifyPin()`.

### _verifyPin() logic:
1. Read `app_pin_hash_<uid>` from SecurePrefs.
2. If null → no PIN set → unlock directly (call `_unlock()`).
3. Call `PinHasher.verifyPin(_pinInput, storedHash)`.
4. If match → check duress: read `duress_pin_hash_<uid>`, verify against `_pinInput`.
   - If duress PIN matches → `DuressManager.performWipe()`.
   - Else → `_unlock()`.
5. If no match → `_errorText = "Incorrect PIN"`, clear `_pinInput`, shake animation on dots.
6. After 5 failed attempts → `_confirmSignOut()` automatically.

### _unlock():
```dart
AppLockManager.instance.lockScreenActive = false;
AppLockManager.instance.clearBackgroundTs();
Navigator.of(context).pop();
```

### Biometric key:
- Show only if device supports biometrics and biometric unlock is enabled in settings.
- On tap: call `LocalAuthentication.authenticate(localizedReason: 'Unlock DuoShield')`.
- On success: `_unlock()`.

---

## 28. SCREEN: SETTINGS

**File:** `lib/screens/settings/settings_screen.dart`  
**Route:** `/settings`  
**Applies:** BaseScreen mixin.

### Layout
```
Scaffold(backgroundColor: colorBackground)
AppBar: title 'Settings'
Body: ListView:
  // Profile section
  Padding(16): Row:
    CircleAvatar(radius:32, ...)
    SizedBox(16)
    Column:
      Text(displayName, fontSize:18, bold)
      Text(userId, fontSize:12, colorTextSecondary, fontFamily:monospace)
    Spacer()
    IconButton(Icons.edit → _editDisplayName())
  
  Divider(color:colorDivider)
  
  // Section: Security
  _SectionHeader('Security')
  _SettingsTile(
    icon: Icons.lock_outline
    title: 'App PIN'
    subtitle: _hasPIN ? 'Enabled' : 'Not set'
    onTap: → /settings/privacy
  )
  _SettingsTile(
    icon: Icons.fingerprint
    title: 'Biometric Unlock'
    trailing: Switch(value:_biometricEnabled, onChanged:_toggleBiometric)
  )
  _SettingsTile(
    icon: Icons.timer_outlined
    title: 'Auto Lock'
    subtitle: '30 seconds'
    onTap: → (no-op, hardcoded)
  )
  
  Divider(color:colorDivider)
  
  // Section: Notifications
  _SectionHeader('Notifications')
  _SettingsTile(
    icon: Icons.notifications_outlined
    title: 'Notification Settings'
    onTap: → /settings/notifications
  )
  
  Divider(color:colorDivider)
  
  // Section: Privacy
  _SectionHeader('Privacy')
  _SettingsTile(icon:Icons.privacy_tip_outlined, title:'Privacy Settings', onTap:→/settings/privacy)
  
  Divider(color:colorDivider)
  
  // Section: Data
  _SectionHeader('Data')
  _SettingsTile(icon:Icons.backup_outlined, title:'Backup & Restore', onTap:→/settings/backup)
  
  Divider(color:colorDivider)
  
  // Section: About
  _SectionHeader('About')
  _SettingsTile(icon:Icons.info_outline, title:'Version', subtitle: appVersion)
  _SettingsTile(icon:Icons.security, title:'Verify Safety Numbers', onTap:→/safety-numbers)
  
  Divider(color:colorDivider)
  
  // Sign out
  Padding(16): DSButton(
    text: 'Sign Out'
    style: outlined, borderColor:colorError, textColor:colorError
    onTap: → _confirmSignOut()
  )
  SizedBox(24)
```

### Sub-screens (separate routes):

**Privacy Settings (`/settings/privacy`):**
- Change PIN: current PIN verification → new PIN (4 digits) → confirm → save.
- Duress PIN: set/change duress PIN (same 4-digit flow, separate key).
- Read receipts: Toggle → write to `users/{uid}` Firestore field `readReceiptsEnabled`.
- Last seen: Toggle → write to `users/{uid}` field `showLastSeen`.

**Notification Settings (`/settings/notifications`):**
- Message notifications: Toggle → `flutter_local_notifications` channel setting.
- Call notifications: Toggle → same.
- Notification preview: show message text / show 'New message' / nothing → 3-option radio.

**Backup Settings (`/settings/backup`):** → see §31.

### _editDisplayName():
```
AlertDialog:
  title: 'Edit Display Name'
  content: TextField(controller: pre-filled, maxLength:32)
  actions:
    TextButton('Cancel')
    TextButton('Save'):
      Firestore write users/{uid} displayName
      SecurePrefs update
      setState to reload UI
```

---

## 29. SCREEN: SAFETY NUMBERS

**File:** `lib/screens/safety_numbers/safety_numbers_screen.dart`  
**Route:** `/safety-numbers`  
**Params:** `partnerUid`  
**Applies:** BaseScreen mixin.

### Layout
```
Scaffold(backgroundColor: colorBackground)
AppBar: title 'Safety Numbers'
Body: Padding(24): Column:
  Text('Verify you\'re talking to the right person.', colorTextSecondary, fontSize:13)
  SizedBox(24)
  Text('Your code', colorTextMuted, fontSize:11)
  SizedBox(8)
  _SafetyCodeGrid(myCode)   // 12 groups of 5 digits each
  SizedBox(24)
  Text('Their code', colorTextMuted, fontSize:11)
  SizedBox(8)
  _SafetyCodeGrid(partnerCode)
  SizedBox(32)
  Text(
    'If both codes match, you can confirm your conversation is secure.',
    colorTextSecondary, fontSize:12, textAlign:center
  )
  SizedBox(24)
  DSButton(
    text: 'Mark as Verified'
    gradient: true
    onTap: → _verify()
  )
```

### Safety number calculation:
1. Load own identity key bytes and partner's identity key bytes (from Firestore `identities/{userId}`).
2. Concatenate: `myKey + partnerKey` (or sorted by uid alphabetically for determinism).
3. SHA-512 hash the concatenation.
4. Convert hash to 60-digit decimal string by treating as BigInteger mod 10^60.
5. Split into 12 groups of 5 digits: `12345 67890 12345 ...`.

### _verify():
1. Update local `signal_identities` table: `verified = 1` for `address = partnerUid`.
2. Remove SecurePrefs key `safety_num_changed_<partnerUid>`.
3. Show SnackBar `"Contact verified"`.
4. Navigator.pop().

---

## 30. SCREEN: MEDIA VIEWER

**File:** `lib/screens/media_viewer/media_viewer_screen.dart`  
**Route:** `/media-viewer`  
**Params:** `mediaUrl`, `mediaType`, `mediaKey`  
**Applies:** BaseScreen mixin.

### Layout
```
Scaffold(backgroundColor: Colors.black)
AppBar: transparent, white back arrow, white download icon (trailing)
Body: Center:
  if mediaType == 'image':
    InteractiveViewer(
      child: CachedNetworkImage or FutureBuilder<Uint8List>(
        future: _decryptAndLoad()
        builder: (_, snap) {
          if snap.hasData → Image.memory(snap.data!)
          else → CircularProgressIndicator(color:colorAccent)
        }
      )
    )
  
  if mediaType == 'video':
    AspectRatio(
      aspectRatio: _controller?.value.aspectRatio ?? 16/9
      child: VideoPlayer(_controller!)
    )
    // Play/pause on tap
  
  if mediaType == 'audio':
    WaveformView + play/pause controls
```

### Download button:
- Decrypt media → save to device Downloads folder → show SnackBar `"Saved to Downloads"`.

### Null checks (crash guard):
- Check `mounted && !context.mounted` before any `setState` or `Navigator` call in async callbacks.
- Check `_controller != null` before calling VideoPlayer methods.

---

## 31. SCREEN: BACKUP & RESTORE SETTINGS

**File:** `lib/screens/settings/backup_settings_screen.dart`  
**Route:** `/settings/backup`  
**Applies:** BaseScreen mixin.

### Layout
```
Scaffold(backgroundColor: colorBackground)
AppBar: title 'Backup & Restore'
Body: Padding(24): Column:
  _SectionHeader('Backup')
  Text('Your backup is encrypted with your seed phrase.', colorTextSecondary, fontSize:13)
  SizedBox(16)
  DSButton(text:'Create Backup', gradient:true, onTap:→_createBackup())
  SizedBox(8)
  if _lastBackupDate != null:
    Text('Last backup: ${formatDate(_lastBackupDate!)}', colorTextMuted, fontSize:12)
  
  SizedBox(32)
  _SectionHeader('Restore')
  Text('Import a .dsbak file to restore messages.', colorTextSecondary, fontSize:13)
  SizedBox(16)
  OutlinedButton(
    text: 'Import Backup File'
    icon: Icons.upload_file
    onTap: → _importBackup()
  )
```

### _createBackup() logic:
1. Query all messages from local DB.
2. Serialize to JSON.
3. Encrypt with `BackupCryptoHelper.encrypt(backupKey, jsonBytes)`.
4. Write to file `duoshield_backup_<timestamp>.dsbak` in app documents directory.
5. Share via `Share.shareFiles([filePath])`.
6. Store `lastBackupDate = now` in SecurePrefs.

### _importBackup() logic:
1. `FilePicker.platform.pickFiles(allowedExtensions:['dsbak'])`.
2. Read file bytes.
3. Decrypt with `BackupCryptoHelper.decrypt(backupKey, bytes)`.
4. Parse JSON → list of messages.
5. Insert all into local DB (ignore conflicts with `INSERT OR IGNORE`).
6. Show SnackBar `"Restored N messages from backup"`.

---

## 32. NOTIFICATIONS

### FCM Message Types (check `data['type']` field):

| type              | Action                                                         |
|-------------------|----------------------------------------------------------------|
| `message`         | Show local notification; route to /chat on tap                 |
| `group_message`   | Show local notification; route to /group-chat on tap          |
| `incoming_call`   | Show full-screen call notification or CallScreen if foreground |
| `ack`             | Update message delivery status in local DB; no notification   |
| `group_key`       | Fetch and store new group key; no notification                 |

### FCM Data Fields:

**message:**
```json
{ "type": "message", "chatId": "...", "senderId": "...", "senderUid": "...",
  "senderName": "...", "preview": "New message" }
```

**incoming_call:**
```json
{ "type": "incoming_call", "callId": "...", "callerId": "...",
  "callerName": "...", "isVideo": "false" }
```

**ack:**
```json
{ "type": "ack", "chatId": "...", "messageId": "...", "status": "delivered" }
```

### Local Notification Setup (flutter_local_notifications):
- Channel ID: `duoshield_messages`
- Channel name: `Messages`
- Importance: `Importance.high`
- Sound: default
- On notification tap: extract `chatId` and `partnerUid` from payload, navigate to `/chat/{chatId}`.

### OneSignal Setup:
- Init with OneSignal App ID (from BuildConfig).
- Register OneSignal player ID and write to Firestore `users/{uid}` field `oneSignalId`.

---

## 33. DEEP LINKS

Android Manifest intent filter (add to `android/app/src/main/AndroidManifest.xml`):
```xml
<intent-filter android:autoVerify="true">
  <action android:name="android.intent.action.VIEW"/>
  <category android:name="android.intent.category.DEFAULT"/>
  <category android:name="android.intent.category.BROWSABLE"/>
  <data android:scheme="duoshield" android:host="add"/>
</intent-filter>
```

In GoRouter: add redirect for `duoshield://add/:userId` → `/add-contact?prefill=:userId`.

In AddContactScreen `initState`: read `prefill` param, pre-fill `etContactId`, auto-trigger `_addByUserId()`.

---

## 34. BACKGROUND SERVICES

### Presence Heartbeat (WorkManager — periodic):
- Interval: 15 minutes.
- Task: write `online: true, lastSeen: now` to `users/{uid}`.
- On app foreground: write immediately.
- On app background (AppLifecycleState.paused): write `online: false, lastSeen: now`.

### PreKey Check (WorkManager — periodic):
- Interval: 24 hours.
- Task: count remaining PreKeys in Firestore `identities/{userId}.preKeys`.
- If < 10: generate 25 new PreKeys, upload via `arrayUnion`.

### Signed PreKey Rotation (WorkManager — periodic):
- Interval: 24 hours.
- Task: check last SPK rotation timestamp from SecurePrefs `spk_rotated_at`.
- If > 7 days: generate new SPK, store prev in `signal_signed_prekey_prev`, upload new to Firestore.

### Disappearing Messages (local timer):
- On chat open: for each message with `disappearMs != null` and that was sent by partner and has been read: start a `Timer(Duration(milliseconds: disappearMs))`.
- On timer fire: delete message from local DB and adapter. Write `deletedForAll: true` to Firestore.

---

## 35. NAVIGATION (GoRouter)

```dart
final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
    GoRoute(path: '/sign-in', builder: (_, __) => const SignInScreen()),
    GoRoute(path: '/display-name', builder: (_, __) => const DisplayNameScreen()),
    GoRoute(path: '/seed-phrase-display', builder: (_, state) =>
      SeedPhraseDisplayScreen(
        mnemonic: state.extra as Map? ?? {}['mnemonic'],
        displayName: ..., identityKey: ..., userId: ...
      )),
    GoRoute(path: '/restore-from-seed', builder: (_, __) => const RestoreFromSeedScreen()),
    GoRoute(path: '/conversations', builder: (_, __) => const ConversationListScreen()),
    GoRoute(path: '/chat/:conversationId', builder: (_, state) =>
      ChatScreen(conversationId: state.pathParameters['conversationId']!,
                 partnerUid: state.extra as Map? ?? {}['partnerUid'] ?? '')),
    GoRoute(path: '/group-chat/:groupId', builder: (_, state) =>
      GroupChatScreen(groupId: state.pathParameters['groupId']!)),
    GoRoute(path: '/create-group', builder: (_, __) => const CreateGroupScreen()),
    GoRoute(path: '/add-contact', builder: (_, state) =>
      AddContactScreen(prefill: state.uri.queryParameters['prefill'])),
    GoRoute(path: '/contact-detail', builder: (_, state) =>
      ContactDetailScreen(extra: state.extra as Map)),
    GoRoute(path: '/call', builder: (_, state) =>
      CallScreen(extra: state.extra as Map)),
    GoRoute(path: '/call-history', builder: (_, __) => const CallHistoryScreen()),
    GoRoute(path: '/lock', builder: (_, __) => const LockScreen()),
    GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
    GoRoute(path: '/settings/privacy', builder: (_, __) => const PrivacySettingsScreen()),
    GoRoute(path: '/settings/notifications', builder: (_, __) => const NotificationSettingsScreen()),
    GoRoute(path: '/settings/backup', builder: (_, __) => const BackupSettingsScreen()),
    GoRoute(path: '/safety-numbers', builder: (_, state) =>
      SafetyNumbersScreen(partnerUid: state.extra as String)),
    GoRoute(path: '/media-viewer', builder: (_, state) =>
      MediaViewerScreen(extra: state.extra as Map)),
  ],
);
```

**clearStack navigation:** use `context.go(path)` (GoRouter replaces stack).  
**Push navigation:** use `context.push(path)` (GoRouter adds to stack).

---

## 36. STATE MANAGEMENT

Use `flutter_riverpod`. Each provider is in its own file under `lib/providers/`.

### Auth Provider
```dart
// Exposes FirebaseAuth.instance.authStateChanges() as AsyncValue<User?>
final authProvider = StreamProvider<User?>((ref) =>
  FirebaseAuth.instance.authStateChanges());
```

### Conversation Provider
```dart
// Exposes real-time conversation list
final conversationProvider = StreamProvider<List<Conversation>>((ref) {
  final uid = ref.watch(authProvider).value?.uid;
  if (uid == null) return Stream.value([]);
  return ConversationRepository(uid).watchAll();
});
```

### Message Provider
```dart
// Exposes messages for a specific chat
final messageProvider = StreamProvider.family<List<Message>, String>((ref, chatId) {
  return MessageRepository(chatId).watchAll();
});
```

---

## 37. CUSTOM WIDGETS

### 37.1 MatrixRainView (CustomPainter)
```
Parameters:
  color: Color (default colorAccent)
  opacity: double (default 0.4)
  speed: int ms per frame (default 60)

Behavior:
  - Maintain list of Column objects, each with:
      x position (random column)
      y position (starts at random negative offset)
      speed (random between 2–6 pixels per frame)
      glyphs: list of random chars from set: 
        '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZアイウエオカキクケコ'
  - Each frame: advance y by speed
  - If y > canvasHeight: reset y to random negative, randomize x to new column
  - Paint top glyph at full opacity, fade previous 8 glyphs with decreasing opacity
  - Glyph font size: 14sp
  - Column width: 20px
```

### 37.2 TypingDotsView
```
Parameters: none — uses colorAccent

Behavior:
  - 3 circles, diameter 8px, spacing 6px
  - Each animates vertically: translateY 0 → -8 → 0 over 600ms
  - Stagger: dot 2 starts 200ms after dot 1; dot 3 starts 200ms after dot 2
  - Loop continuously while visible
  - Use flutter_animate or manual AnimationController
```

### 37.3 WaveformView (CustomPainter)
```
Parameters:
  List<double> amplitudes  (values 0.0–1.0)
  double progress          (0.0–1.0 scrubber position)
  Color playedColor        (default colorAccent)
  Color unplayedColor      (default colorSurfaceVariant)

Behavior:
  - Draw vertical bars for each amplitude value
  - Bar width: 3px, spacing: 2px
  - Bar height: amplitude * maxHeight
  - Bars before progress point: playedColor
  - Bars after progress point: unplayedColor
  - GestureDetector wraps it for scrubbing (onPanUpdate → update progress)
```

### 37.4 DSTextField
```dart
Widget DSTextField({
  required String hint,
  TextEditingController? controller,
  int? maxLines = 1,
  int? minLines,
  int? maxLength,
  TextInputType? keyboardType,
  TextInputAction? textInputAction,
  TextCapitalization textCapitalization = TextCapitalization.sentences,
  void Function(String)? onChanged,
  bool obscureText = false,
  Widget? suffixIcon,
})

// Style:
// filled: true
// fillColor: colorInputBg
// border: OutlineInputBorder(borderRadius:12, borderSide:BorderSide.none)
// focusedBorder: OutlineInputBorder(borderRadius:12, borderSide:BorderSide(colorAccent, 1.5))
// hintStyle: TextStyle(color:colorTextMuted, fontSize:14)
// contentPadding: EdgeInsets.symmetric(horizontal:16, vertical:14)
```

### 37.5 DSButton
```dart
Widget DSButton({
  required String text,
  required VoidCallback? onTap,
  bool gradient = false,
  bool enabled = true,
  double height = 52,
  double? width,
})

// When gradient=true: DecoratedBox with the 3-stop gradient defined in §3
// When gradient=false: outlined style with colorAccent border
// Disabled: opacity 0.5
// Border radius: 12
// Text: bold, 16sp, colorOnAccent (gradient) or colorAccent (outlined)
```

### 37.6 MessageBubble
```dart
// Max width: 75% of screen width
// Outgoing (mine): align right, colorBubbleMine, border-radius 16 except bottom-right = 4
// Incoming (theirs): align left, colorBubbleTheirs, border-radius 16 except bottom-left = 4

// Content order (top to bottom):
//   [if reply] reply preview box (colorSurface bg, 3dp left border colorAccent)
//   [if media] media thumbnail or audio player
//   [if text] Text(message.text, colorTextPrimary, fontSize:14)
//   [if edited] Text('edited', colorTextMuted, fontSize:10, italic)
//   [if link preview] LinkPreviewCard
//   Row (right-aligned):
//     Text(formattedTime, colorTextMuted, fontSize:10)
//     SizedBox(4)
//     [if mine] StatusIcon (clock/check/double-check/double-check-blue for sending/sent/delivered/read)
//   [if reactions] Row of emoji chips below bubble

// Tombstone (deletedForAll):
//   Text('🚫 This message was deleted', colorTextMuted, italic, fontSize:13)
//   No media, no reply box

// Legacy (sigType==0):
//   Text('[Legacy message — not decryptable]', colorTextMuted, italic, fontSize:13)
```

---

## 38. BUILD & RUN

### Android Manifest permissions (add to `android/app/src/main/AndroidManifest.xml`):
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.BLUETOOTH"/>
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT"/>
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>
<uses-permission android:name="android.permission.READ_MEDIA_VIDEO"/>
<uses-permission android:name="android.permission.READ_MEDIA_AUDIO"/>
<uses-permission android:name="android.permission.VIBRATE"/>
<uses-permission android:name="android.permission.USE_BIOMETRIC"/>
<uses-permission android:name="android.permission.USE_FINGERPRINT"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
<uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS"/>
```

### Build commands:
```bash
# Debug APK
flutter332 build apk --debug

# Release APK (requires keystore)
flutter332 build apk --release \
  --dart-define=PUSH_SERVER_URL=https://duoshield.onrender.com

# Install on connected device
flutter332 install
```

### Keystore (for release):
- File: `android/app/duoshield-release.keystore`
- Alias: `duoshield` (lowercase)
- Read from env vars: `KEY_STORE_PASSWORD`, `KEY_PASSWORD`, `KEY_ALIAS`

### `android/app/build.gradle` signing config:
```groovy
signingConfigs {
  release {
    storeFile file('duoshield-release.keystore')
    storePassword System.getenv('KEY_STORE_PASSWORD')
    keyAlias System.getenv('KEY_ALIAS')?.toLowerCase()
    keyPassword System.getenv('KEY_PASSWORD')
  }
}
```

---

## 39. TESTING CHECKLIST

Every item in this list must pass before the build is considered complete. Test in order.

### 39.1 Account Creation Flow
- [ ] Splash shows MatrixRainView + logo for ≥ 2 seconds
- [ ] Splash routes to SignInScreen (fresh install, no auth)
- [ ] "Create New Account" navigates to DisplayNameScreen
- [ ] Empty name → Continue button is disabled
- [ ] Typing name → Continue button enables
- [ ] Submit with valid name → loading overlay appears
- [ ] 12-word mnemonic generated, all words visible in 4×3 grid
- [ ] "Copy" button copies all 12 words to clipboard
- [ ] "Show QR" shows QR code dialog
- [ ] Checkbox unchecked → Continue button disabled
- [ ] Checkbox checked → Continue button enabled
- [ ] Continue → status text updates through: "Registering identity…" → "Saving profile…" → "Setting up encryption…" → "Done!"
- [ ] Navigates to ConversationList after success

### 39.2 Restore Flow
- [ ] "Restore from Seed Phrase" navigates to RestoreFromSeedScreen
- [ ] Submit with empty fields → error "Please fill in all fields."
- [ ] Submit with 11 words → error "Please enter exactly 12 words."
- [ ] Submit with invalid word → error "Invalid word: '<word>'…"
- [ ] Submit with valid mnemonic but wrong ID → error "Account ID does not match…"
- [ ] Submit with correct mnemonic + ID → step text progresses → navigates to conversations

### 39.3 Lock Screen
- [ ] Entering wrong PIN shows "Incorrect PIN" and clears dots
- [ ] Entering correct PIN unlocks and navigates back
- [ ] Entering duress PIN triggers wipe flow
- [ ] After wipe, SignInScreen shows with fresh state
- [ ] Biometric button visible only if biometrics enrolled and setting enabled
- [ ] Biometric auth success unlocks
- [ ] Sign out link shows confirm dialog
- [ ] AppLockManager.lockScreenActive prevents double lock screen

### 39.4 Conversation List
- [ ] Shimmer shows while loading
- [ ] Empty state shows "No conversations yet" + Add Contact button
- [ ] Conversations list populates from Firestore
- [ ] Unread badge shows correct count
- [ ] Mute icon visible for muted conversations
- [ ] Swipe left archives conversation
- [ ] Archived banner appears if archived count > 0
- [ ] Tap archived banner → shows archived conversations
- [ ] Search filters by partner name in real-time
- [ ] Popup menu has items: New Chat, New Group, Settings, [divider], Wipe & Exit
- [ ] Wipe & Exit shows confirm dialog with "This cannot be undone" text
- [ ] FAB navigates to AddContact

### 39.5 Chat
- [ ] Messages load from local DB first, then Firestore
- [ ] Outgoing bubble is right-aligned, colorBubbleMine
- [ ] Incoming bubble is left-aligned, colorBubbleTheirs
- [ ] Status icons: clock (sending) → single check (sent) → double check gray (delivered) → double check blue (read)
- [ ] Send button disabled immediately on tap, re-enabled after Firestore ack
- [ ] Empty text field → voice note button visible
- [ ] Non-empty text field → send button visible
- [ ] Long-press voice note button → recording starts
- [ ] Release voice note button → sends voice note
- [ ] Long-press message → action sheet appears with emoji row + 8 action items
- [ ] Reply sets reply bar above input
- [ ] Edit shows dialog prefilled with current text
- [ ] "Delete for everyone" removes bubble on both sides
- [ ] "Delete locally" removes bubble on this device only
- [ ] Disappear timer dialog has 6 options
- [ ] Safety number banner appears if key changed
- [ ] Verify clears banner
- [ ] Dismiss (✕) hides banner for session only
- [ ] Typing indicator appears within 1s of partner typing
- [ ] Partner status shows "Online" or "Last seen …"
- [ ] Link preview card shows for URLs in messages
- [ ] Attachment menu has 4 options: Camera, Gallery, Audio, File
- [ ] Media message shows thumbnail in bubble
- [ ] Tap media → MediaViewer

### 39.6 Group Chat
- [ ] Sender name shown above each incoming bubble
- [ ] Correct decryption with group AES key
- [ ] Group menu has: Group Info, Add Member, Leave Group
- [ ] Leave Group calls /removeGroupMember and removes from local DB

### 39.7 Add Contact
- [ ] QR tab opens camera scanner
- [ ] Scanning valid QR adds contact and navigates to chat
- [ ] Entering invalid format → "Invalid DuoShield ID format"
- [ ] Entering non-existent ID → "User not found"
- [ ] Entering valid ID → creates chat → navigates to ChatScreen
- [ ] Share tab shows own DuoShield ID and copy/share buttons
- [ ] deep link `duoshield://add/XXXXX-XXXXX-XXX` opens AddContact with ID prefilled

### 39.8 Call
- [ ] Voice call: no video renderers rendered
- [ ] Video call: local PiP bottom-right, remote full screen
- [ ] Call status text: "Calling…" → "Connected" → timer counting up
- [ ] Mute button toggles mic mute, button color changes to red when muted
- [ ] End call: writes status "ended", disposes peer connection + renderers, navigates back
- [ ] Accept incoming call: TURN fetched before answer created
- [ ] onTrack handler enables audio track (one-way audio bug is not present)
- [ ] ICE disconnect triggers restartIce()
- [ ] In-call chat sends and receives messages in calls/{callId}/chat
- [ ] Call record inserted to local DB after call ends

### 39.9 Settings
- [ ] Display name editable → saved to Firestore and UI
- [ ] Change PIN flow: enter current → enter new (4 digits) → confirm → saved with PBKDF2
- [ ] Duress PIN set separately → entered on lock screen → wipe triggered
- [ ] Backup creates .dsbak file and triggers share sheet
- [ ] Import backup decrypts and shows "Restored N messages" toast
- [ ] Biometric toggle persists and affects lock screen behavior
- [ ] Sign out → Firebase sign out + clear local state → navigate to SignIn

### 39.10 Safety Numbers
- [ ] Codes are 60 digits split into 12 groups of 5
- [ ] My code and partner code displayed separately
- [ ] Codes are deterministic (same for same keypair)
- [ ] "Mark as Verified" updates local DB and removes banner flag
- [ ] Navigates back after verify

### 39.11 Crypto Correctness
- [ ] HKDF output is exactly 32 bytes for length=32
- [ ] PBKDF2 uses exactly 310,000 iterations
- [ ] PIN hash format is exactly `hexSalt:hexHash`
- [ ] Signal encrypt → Signal decrypt round-trip produces same plaintext
- [ ] Group encrypt → Group decrypt round-trip with AES-GCM correct
- [ ] Database key derivation produces consistent key from same UID
- [ ] BIP39 mnemonic → DuoShield ID is deterministic (same phrase = same ID every time)
- [ ] Custom base32 alphabet contains no I, O, 1, 0

### 39.12 Auto Sign-Out & Lock
- [ ] Background for > 30s → lock screen on next foreground
- [ ] Background for > 15min → auto sign-out on next foreground
- [ ] Auto sign-out shows inactivity snackbar on SignIn screen
- [ ] Auto sign-out clears: is_paired, conversation_id, partner_uid, disappear_ms
- [ ] Double lock screen never stacked (lockScreenActive guard works)

---
*End of document. Every item is final. Do not deviate.*
