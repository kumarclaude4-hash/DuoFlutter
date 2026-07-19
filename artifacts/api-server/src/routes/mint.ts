import { Router } from "express";
import { getAuth } from "firebase-admin/auth";
import { getFirebaseApp } from "../lib/firebase.js";

const router = Router();

const AUTH_SECRET = process.env.AUTH_SECRET;
const UID_PATTERN = /^[A-Z2-7]{5}-[A-Z2-7]{5}-[A-Z2-7]{3}$/;

/**
 * POST /api/mintToken
 * Body: { uid: string, secret: string }
 * Response: { token: string }
 */
router.post("/mintToken", async (req, res) => {
  const { uid, secret } = req.body as { uid?: string; secret?: string };

  if (!uid || typeof uid !== "string" || uid.trim().length === 0) {
    res.status(400).json({ error: "uid is required" });
    return;
  }

  if (!secret || secret !== AUTH_SECRET) {
    console.warn("[mintToken] Bad secret attempt for uid:", uid);
    res.status(403).json({ error: "Invalid secret" });
    return;
  }

  if (!UID_PATTERN.test(uid)) {
    res.status(400).json({ error: "uid format invalid" });
    return;
  }

  try {
    const auth = getAuth(getFirebaseApp());
    let userRecord;
    try {
      userRecord = await auth.getUserByEmail(`${uid}@duoshield.app`);
    } catch (notFound: unknown) {
      const code = (notFound as { code?: string }).code;
      if (code === "auth/user-not-found") {
        userRecord = await auth.createUser({
          uid,
          email: `${uid}@duoshield.app`,
          displayName: uid,
        });
        console.log("[mintToken] Created new user:", uid);
      } else {
        throw notFound;
      }
    }

    const token = await auth.createCustomToken(userRecord.uid);
    console.log("[mintToken] Minted token for:", uid);
    res.json({ token });
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : String(err);
    console.error("[mintToken] Error:", message);
    res.status(500).json({ error: "Token minting failed" });
  }
});

export default router;
