# DuoShield Push Server

Node.js/Express backend for the DuoShield encrypted messaging app.

## What it does

| Endpoint | Auth | Purpose |
|---|---|---|
| `GET /healthz` | None | Render health check |
| `POST /mintToken` | Shared secret | Mint Firebase custom auth token for a new user |
| `POST /createChat` | Firebase ID token | Create Firestore chat document between two users |
| `POST /migrateUid` | Firebase ID token | Re-link Firestore data after seed phrase restore |
| `POST /removeGroupMember` | Firebase ID token | Remove a member from a group (admin only) |
| `POST /turnCredentials` | Firebase ID token | Generate Cloudflare TURN credentials (HMAC-SHA256) |
| `POST /b2PresignedPut` | Firebase ID token | Presigned upload URL for encrypted media |
| `POST /b2PresignedGet` | Firebase ID token | Presigned download URL for encrypted media |
| `POST /b2Delete` | Firebase ID token | Delete media object from B2 |
| `POST /linkPreview` | Firebase ID token | Fetch OG metadata for a URL (server-side, avoids SSRF) |

---

## Deploy to Render (free tier)

### 1. Push this folder to GitHub

```bash
# From the workspace root
git init duoshield_server
cd duoshield_server
git add .
git commit -m "Initial push server"
gh repo create duoshield-server --private --push
```

Or: create a GitHub repo manually and push.

### 2. Create a new Render Web Service

1. Go to [render.com](https://render.com) → **New** → **Web Service**
2. Connect your GitHub repo
3. Set:
   - **Build command:** `npm install`
   - **Start command:** `npm start`
   - **Node version:** 18+

The `render.yaml` in the repo root handles this automatically if you use Render's Blueprint deploy.

### 3. Configure environment variables in Render

Set these in the Render dashboard under **Environment**:

#### Required — Firebase Admin

Get the service account JSON from Firebase Console → Project Settings → Service Accounts → Generate new private key.

Paste the entire JSON as a single line into:
```
FIREBASE_SERVICE_ACCOUNT_JSON = {"type":"service_account","project_id":"..."}
```

#### Required — Auth secret

```
AUTH_SECRET = <any long random string>
```

Generate one: `openssl rand -hex 32`

**Copy this exact string into the Flutter app** — search for `'AUTH_SECRET'` in:
- `duoshield_app/lib/screens/auth/display_name_screen.dart`
- `duoshield_app/lib/screens/auth/restore_from_seed_screen.dart`

#### Required for calls — Cloudflare TURN

1. Go to Cloudflare Dashboard → Zero Trust → Networks → TURN
2. Create a TURN service → copy the API token and Key ID

```
CLOUDFLARE_TURN_API_TOKEN = <your token>
CLOUDFLARE_TURN_KEY_ID    = <your key id>
TURN_TTL                  = 86400
```

#### Required for media — Backblaze B2

1. Create a B2 bucket (private, not public)
2. Create an App Key with Read + Write access to that bucket

```
B2_KEY_ID          = <application key id>
B2_APPLICATION_KEY = <application key>
B2_BUCKET_NAME     = <bucket name>
B2_ENDPOINT        = https://s3.us-west-004.backblazeb2.com
B2_PRESIGN_TTL     = 3600
```

> Find your region endpoint in B2 Console → Buckets → click your bucket → Endpoint.

### 4. Set the Render URL in the Flutter app

Once Render deploys, your URL will be `https://duoshield-server.onrender.com` (or similar).

Open `duoshield_app/lib/core/constants.dart` and update:
```dart
static const String pushServerUrl = 'https://your-actual-render-url.onrender.com';
```

### 5. Verify

```bash
curl https://your-render-url.onrender.com/healthz
# Expected: {"status":"ok","ts":1234567890}
```

---

## Local development

```bash
cp .env.example .env
# Edit .env with your credentials

npm install
npm run dev  # uses nodemon for auto-reload
```

Test /healthz:
```bash
curl http://localhost:3000/healthz
```

Test /mintToken:
```bash
curl -X POST http://localhost:3000/mintToken \
  -H "Content-Type: application/json" \
  -d '{"uid":"AAAAA-BBBBB-CCC","secret":"your_secret_here"}'
```

---

## Architecture

```
src/
├── index.js            ← Express app + middleware + route mounting
├── firebase.js         ← Firebase Admin singleton (reads env vars)
├── middleware/
│   └── auth.js         ← Firebase ID token verification
└── routes/
    ├── mint.js         ← /mintToken (no auth, secret-gated)
    ├── chat.js         ← /createChat, /migrateUid, /removeGroupMember
    ├── turn.js         ← /turnCredentials (HMAC-SHA256 Cloudflare TURN)
    ├── b2.js           ← /b2PresignedPut, /b2PresignedGet, /b2Delete
    └── linkPreview.js  ← /linkPreview (SSRF-protected OG scraper)
```

### Security

- **All routes except `/healthz` and `/mintToken`** require a valid Firebase ID token.
- **`/mintToken`** requires the shared `AUTH_SECRET` — rate limited to 10 req/min.
- **`/linkPreview`** blocks private/local IP ranges (SSRF protection) and enforces a 8s fetch timeout.
- **B2 key validation** rejects keys with path traversal characters.
- **Helmet** sets secure HTTP headers.
- **Rate limiting**: 120 req/min globally, stricter on sensitive endpoints.

### TURN credential generation

Cloudflare TURN uses time-limited HMAC-SHA256 credentials:
```
expiry   = now_unix + TTL
username = "<expiry>:<uid>"
cred     = base64(HMAC-SHA256(key=TURN_API_TOKEN, msg=username))
```

The Flutter app caches these for up to 23 hours (refreshes before expiry).

### B2 media encryption

The server only generates presigned URLs — it never sees the plaintext media. The Flutter app:
1. Generates a random 32-byte `mediaKey`
2. Encrypts the file: `AES-256-GCM(key=mediaKey, nonce=random12)`
3. Uploads the ciphertext via the presigned PUT URL
4. Stores `mediaKey` (base64) + `b2:<objectKey>` in Firestore

On download, the receiver fetches the ciphertext and decrypts with the `mediaKey` from Firestore.

---

## Firestore data model (used by this server)

```
chats/{chatId}
  participants: [uid1, uid2]       // sorted alphabetically
  createdAt: Timestamp
  lastMessage: string
  lastMessageTs: number

identities/{uid}
  uid: string
  identityKey: string              // base64 Signal identity key
  preKeys: array
  signedPreKey: object

groups/{groupId}
  name: string
  createdBy: uid
  members: [uid, ...]
  members/{uid}                    // subcollection
    displayName: string
    joinedAt: Timestamp
```
