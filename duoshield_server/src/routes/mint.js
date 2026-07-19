const express = require('express');
const admin = require('../firebase');

const router = express.Router();

const AUTH_SECRET = process.env.AUTH_SECRET;

/**
 * POST /mintToken
 * Body: { uid: string, secret: string }
 * Response: { token: string }
 *
 * Called by the Flutter app BEFORE the user has a Firebase ID token,
 * so this endpoint does NOT use the requireAuth middleware.
 * It instead verifies the shared AUTH_SECRET.
 */
router.post('/mintToken', async (req, res) => {
  const { uid, secret } = req.body;

  if (!uid || typeof uid !== 'string' || uid.trim().length === 0) {
    return res.status(400).json({ error: 'uid is required' });
  }

  if (!secret || secret !== AUTH_SECRET) {
    console.warn('[mintToken] Bad secret attempt for uid:', uid);
    return res.status(403).json({ error: 'Invalid secret' });
  }

  // uid format: XXXXX-XXXXX-XXX (validated loosely)
  const uidPattern = /^[A-Z2-7]{5}-[A-Z2-7]{5}-[A-Z2-7]{3}$/;
  if (!uidPattern.test(uid)) {
    return res.status(400).json({ error: 'uid format invalid' });
  }

  try {
    // Check if user already exists in Firebase Auth; create if not
    let userRecord;
    try {
      userRecord = await admin.auth().getUserByEmail(`${uid}@duoshield.app`);
    } catch (notFound) {
      if (notFound.code === 'auth/user-not-found') {
        userRecord = await admin.auth().createUser({
          uid: uid,
          email: `${uid}@duoshield.app`,
          displayName: uid,
        });
        console.log('[mintToken] Created new user:', uid);
      } else {
        throw notFound;
      }
    }

    const token = await admin.auth().createCustomToken(userRecord.uid);
    console.log('[mintToken] Minted token for:', uid);
    return res.json({ token });
  } catch (err) {
    console.error('[mintToken] Error:', err.message);
    return res.status(500).json({ error: 'Token minting failed' });
  }
});

module.exports = router;
