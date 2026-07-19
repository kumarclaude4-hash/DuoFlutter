const express = require('express');
const crypto = require('crypto');
const { requireAuth } = require('../middleware/auth');

const router = express.Router();

const CLOUDFLARE_TURN_API_TOKEN = process.env.CLOUDFLARE_TURN_API_TOKEN;
const CLOUDFLARE_TURN_KEY_ID = process.env.CLOUDFLARE_TURN_KEY_ID;
const TURN_TTL = parseInt(process.env.TURN_TTL || '86400', 10);

// Cloudflare TURN servers
const TURN_SERVERS = [
  'turn:turn.cloudflare.com:3478?transport=udp',
  'turn:turn.cloudflare.com:3478?transport=tcp',
  'turn:turn.cloudflare.com:443?transport=tcp',
  'turns:turn.cloudflare.com:443?transport=tcp',
];
const STUN_SERVERS = ['stun:stun.cloudflare.com:3478'];

/**
 * POST /turnCredentials
 * Body: {} (auth header required)
 * Response: { username: string, credential: string, ttl: number, servers: string[] }
 *
 * Generates time-limited Cloudflare TURN credentials via HMAC-SHA256.
 * Formula: username = "<expiry>:<userId>", credential = HMAC-SHA256(key=apiToken, msg=username)
 */
router.post('/turnCredentials', requireAuth, async (req, res) => {
  if (!CLOUDFLARE_TURN_API_TOKEN || !CLOUDFLARE_TURN_KEY_ID) {
    return res.status(503).json({ error: 'TURN not configured on server' });
  }

  try {
    const uid = req.user.uid;
    const expiry = Math.floor(Date.now() / 1000) + TURN_TTL;
    const username = `${expiry}:${uid}`;

    const credential = crypto
      .createHmac('sha256', CLOUDFLARE_TURN_API_TOKEN)
      .update(username)
      .digest('base64');

    console.log('[turnCredentials] Generated for uid:', uid, 'expires:', expiry);

    return res.json({
      username,
      credential,
      ttl: TURN_TTL,
      servers: TURN_SERVERS,
      stun: STUN_SERVERS,
      keyId: CLOUDFLARE_TURN_KEY_ID,
    });
  } catch (err) {
    console.error('[turnCredentials] Error:', err.message);
    return res.status(500).json({ error: 'turnCredentials failed' });
  }
});

module.exports = router;
