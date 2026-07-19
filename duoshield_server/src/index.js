require('dotenv').config();

// Initialize Firebase Admin before anything else
require('./firebase');

const express = require('express');
const helmet = require('helmet');
const cors = require('cors');
const rateLimit = require('express-rate-limit');

const mintRouter = require('./routes/mint');
const chatRouter = require('./routes/chat');
const turnRouter = require('./routes/turn');
const b2Router = require('./routes/b2');
const linkPreviewRouter = require('./routes/linkPreview');

const app = express();
const PORT = process.env.PORT || 3000;

// ─── Security middleware ─────────────────────────────────────────────────────
app.use(helmet());

// Only allow requests from the DuoShield app — in production, the "origin" of
// a mobile app is typically null or the app's package identifier; CORS is
// mainly useful here for any web-based admin tooling.
app.use(cors({
  origin: process.env.NODE_ENV === 'production'
    ? ['https://duoshield.app', 'https://duoshield.onrender.com']
    : '*',
  methods: ['GET', 'POST'],
}));

// ─── Body parsing ────────────────────────────────────────────────────────────
app.use(express.json({ limit: '64kb' }));

// ─── Rate limiting ───────────────────────────────────────────────────────────
// General limiter: 120 req / 1 min per IP
const generalLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 120,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Too many requests, please slow down.' },
});

// Stricter limiter for token minting (prevents brute-force of AUTH_SECRET)
const mintLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 10,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Too many mint requests.' },
});

// Stricter limiter for link preview (prevents SSRF abuse / DDoS)
const previewLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 30,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Too many link preview requests.' },
});

app.use(generalLimiter);

// ─── Health check (no auth) ──────────────────────────────────────────────────
app.get('/healthz', (_req, res) => {
  res.json({ status: 'ok', ts: Date.now() });
});

// ─── Routes ──────────────────────────────────────────────────────────────────
app.use(mintLimiter, mintRouter);     // POST /mintToken
app.use(chatRouter);                  // POST /createChat, /migrateUid, /removeGroupMember
app.use(turnRouter);                  // POST /turnCredentials
app.use(b2Router);                    // POST /b2PresignedPut, /b2PresignedGet, /b2Delete
app.use(previewLimiter, linkPreviewRouter); // POST /linkPreview

// ─── 404 catch-all ──────────────────────────────────────────────────────────
app.use((_req, res) => {
  res.status(404).json({ error: 'Not found' });
});

// ─── Global error handler ────────────────────────────────────────────────────
app.use((err, _req, res, _next) => {
  console.error('[server] Unhandled error:', err.stack || err.message);
  res.status(500).json({ error: 'Internal server error' });
});

// ─── Start ───────────────────────────────────────────────────────────────────
app.listen(PORT, () => {
  console.log(`[server] DuoShield push server listening on port ${PORT}`);
  console.log(`[server] NODE_ENV: ${process.env.NODE_ENV || 'development'}`);
});
