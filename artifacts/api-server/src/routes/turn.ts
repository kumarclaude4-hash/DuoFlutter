import { Router } from "express";
import crypto from "crypto";
import { requireAuth, type AuthedRequest } from "../middlewares/requireAuth.js";

const router = Router();

const CLOUDFLARE_TURN_API_TOKEN = process.env.CLOUDFLARE_TURN_API_TOKEN;
const CLOUDFLARE_TURN_KEY_ID = process.env.CLOUDFLARE_TURN_KEY_ID;
const TURN_TTL = parseInt(process.env.TURN_TTL ?? "86400", 10);

const TURN_SERVERS = [
  "turn:turn.cloudflare.com:3478?transport=udp",
  "turn:turn.cloudflare.com:3478?transport=tcp",
  "turn:turn.cloudflare.com:443?transport=tcp",
  "turns:turn.cloudflare.com:443?transport=tcp",
];
const STUN_SERVERS = ["stun:stun.cloudflare.com:3478"];

/**
 * POST /api/turnCredentials
 * Response: { username, credential, ttl, servers, stun, keyId }
 */
router.post("/turnCredentials", requireAuth, (req: AuthedRequest, res) => {
  if (!CLOUDFLARE_TURN_API_TOKEN || !CLOUDFLARE_TURN_KEY_ID) {
    res.status(503).json({ error: "TURN not configured on server" });
    return;
  }

  try {
    const uid = req.user!.uid;
    const expiry = Math.floor(Date.now() / 1000) + TURN_TTL;
    const username = `${expiry}:${uid}`;

    const credential = crypto
      .createHmac("sha256", CLOUDFLARE_TURN_API_TOKEN)
      .update(username)
      .digest("base64");

    console.log("[turnCredentials] Generated for uid:", uid, "expires:", expiry);

    res.json({
      username,
      credential,
      ttl: TURN_TTL,
      servers: TURN_SERVERS,
      stun: STUN_SERVERS,
      keyId: CLOUDFLARE_TURN_KEY_ID,
    });
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : String(err);
    console.error("[turnCredentials] Error:", message);
    res.status(500).json({ error: "turnCredentials failed" });
  }
});

export default router;
