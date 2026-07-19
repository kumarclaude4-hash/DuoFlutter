import type { Request, Response, NextFunction } from "express";
import { getAuth, type DecodedIdToken } from "firebase-admin/auth";
import { getFirebaseApp } from "../lib/firebase.js";

export interface AuthedRequest extends Request {
  user?: DecodedIdToken;
}

/**
 * Verifies the Firebase ID token in Authorization: Bearer <token>.
 * Attaches decoded token to req.user on success.
 */
export async function requireAuth(
  req: AuthedRequest,
  res: Response,
  next: NextFunction
): Promise<void> {
  const header = req.headers["authorization"];
  if (!header || !header.startsWith("Bearer ")) {
    res
      .status(401)
      .json({ error: "Missing or malformed Authorization header" });
    return;
  }

  const idToken = header.slice(7);
  try {
    const decoded = await getAuth(getFirebaseApp()).verifyIdToken(idToken);
    req.user = decoded;
    next();
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : String(err);
    console.error("[auth] Token verification failed:", message);
    res.status(401).json({ error: "Invalid or expired token" });
  }
}
