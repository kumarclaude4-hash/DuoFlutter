const admin = require('../firebase');

/**
 * Verifies the Firebase ID token in Authorization: Bearer <token>.
 * Attaches decoded token to req.user on success.
 */
async function requireAuth(req, res, next) {
  const header = req.headers['authorization'];
  if (!header || !header.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Missing or malformed Authorization header' });
  }

  const idToken = header.slice(7);
  try {
    const decoded = await admin.auth().verifyIdToken(idToken);
    req.user = decoded;
    next();
  } catch (err) {
    console.error('[auth] Token verification failed:', err.message);
    return res.status(401).json({ error: 'Invalid or expired token' });
  }
}

module.exports = { requireAuth };
