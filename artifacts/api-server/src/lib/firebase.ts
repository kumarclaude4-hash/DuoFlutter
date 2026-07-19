import { initializeApp, getApps, cert, type App } from "firebase-admin/app";

let app: App | undefined;

function getFirebaseApp(): App {
  if (app) return app;
  if (getApps().length > 0) {
    app = getApps()[0];
    return app!;
  }

  const saJson =
    process.env.GOOGLE_APPLICATION_CREDENTIALS_JSON ||
    process.env.FIREBASE_SERVICE_ACCOUNT_JSON;

  if (!saJson) {
    throw new Error(
      "Firebase credentials not configured. Set GOOGLE_APPLICATION_CREDENTIALS_JSON."
    );
  }

  const serviceAccount = JSON.parse(saJson);
  app = initializeApp({
    credential: cert(serviceAccount),
  });
  console.log("[firebase] Admin SDK initialised");
  return app;
}

// Initialise on module load
getFirebaseApp();

export { getFirebaseApp };
