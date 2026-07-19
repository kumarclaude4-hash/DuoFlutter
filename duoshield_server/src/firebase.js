const admin = require('firebase-admin');

let initialized = false;

function initFirebase() {
  if (initialized) return;

  let credential;

  if (process.env.FIREBASE_SERVICE_ACCOUNT_JSON) {
    const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_JSON);
    credential = admin.credential.cert(serviceAccount);
  } else if (process.env.FIREBASE_SERVICE_ACCOUNT_PATH) {
    const serviceAccount = require(
      require('path').resolve(process.env.FIREBASE_SERVICE_ACCOUNT_PATH)
    );
    credential = admin.credential.cert(serviceAccount);
  } else {
    throw new Error(
      'Firebase credentials not configured. Set FIREBASE_SERVICE_ACCOUNT_JSON or FIREBASE_SERVICE_ACCOUNT_PATH.'
    );
  }

  admin.initializeApp({ credential });
  initialized = true;
  console.log('[firebase] Admin SDK initialised');
}

initFirebase();

module.exports = admin;
