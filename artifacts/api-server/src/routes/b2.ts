import { Router } from "express";
import {
  S3Client,
  PutObjectCommand,
  GetObjectCommand,
  DeleteObjectCommand,
} from "@aws-sdk/client-s3";
import { getSignedUrl } from "@aws-sdk/s3-request-presigner";
import { requireAuth, type AuthedRequest } from "../middlewares/requireAuth.js";

const router = Router();

const B2_KEY_ID = process.env.B2_KEY_ID;
const B2_APPLICATION_KEY = process.env.B2_APPLICATION_KEY;
const B2_BUCKET_NAME = process.env.B2_BUCKET_NAME;
const B2_ENDPOINT = process.env.B2_ENDPOINT;
const B2_PRESIGN_TTL = parseInt(process.env.B2_PRESIGN_TTL ?? "3600", 10);

const KEY_PATTERN = /^[\w\-./]+$/;

function getS3Client(): S3Client {
  if (!B2_KEY_ID || !B2_APPLICATION_KEY || !B2_ENDPOINT) {
    throw new Error("B2 credentials not configured");
  }
  return new S3Client({
    endpoint: B2_ENDPOINT,
    region: "us-east-1",
    credentials: {
      accessKeyId: B2_KEY_ID,
      secretAccessKey: B2_APPLICATION_KEY,
    },
    forcePathStyle: true,
  });
}

/** POST /api/b2PresignedPut — presigned PUT URL for encrypted upload */
router.post("/b2PresignedPut", requireAuth, async (_req: AuthedRequest, res) => {
  const { key, contentType } = _req.body as {
    key?: string;
    contentType?: string;
  };

  if (!key || !contentType) {
    res.status(400).json({ error: "key and contentType are required" });
    return;
  }
  if (!KEY_PATTERN.test(key)) {
    res.status(400).json({ error: "Invalid key format" });
    return;
  }

  try {
    const client = getS3Client();
    const command = new PutObjectCommand({
      Bucket: B2_BUCKET_NAME,
      Key: key,
      ContentType: contentType,
    });
    const url = await getSignedUrl(client, command, { expiresIn: B2_PRESIGN_TTL });
    console.log("[b2PresignedPut] Generated PUT URL for key:", key);
    res.json({ url, objectKey: key });
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : String(err);
    console.error("[b2PresignedPut] Error:", message);
    res.status(500).json({ error: "b2PresignedPut failed" });
  }
});

/** POST /api/b2PresignedGet — presigned GET URL for encrypted download */
router.post("/b2PresignedGet", requireAuth, async (_req: AuthedRequest, res) => {
  const { key } = _req.body as { key?: string };

  if (!key) {
    res.status(400).json({ error: "key is required" });
    return;
  }
  if (!KEY_PATTERN.test(key)) {
    res.status(400).json({ error: "Invalid key format" });
    return;
  }

  try {
    const client = getS3Client();
    const command = new GetObjectCommand({ Bucket: B2_BUCKET_NAME, Key: key });
    const url = await getSignedUrl(client, command, { expiresIn: B2_PRESIGN_TTL });
    console.log("[b2PresignedGet] Generated GET URL for key:", key);
    res.json({ url });
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : String(err);
    console.error("[b2PresignedGet] Error:", message);
    res.status(500).json({ error: "b2PresignedGet failed" });
  }
});

/** POST /api/b2Delete — delete an object from B2 */
router.post("/b2Delete", requireAuth, async (_req: AuthedRequest, res) => {
  const { key } = _req.body as { key?: string };

  if (!key) {
    res.status(400).json({ error: "key is required" });
    return;
  }
  if (!KEY_PATTERN.test(key)) {
    res.status(400).json({ error: "Invalid key format" });
    return;
  }

  try {
    const client = getS3Client();
    await client.send(
      new DeleteObjectCommand({ Bucket: B2_BUCKET_NAME, Key: key })
    );
    console.log("[b2Delete] Deleted key:", key);
    res.json({ success: true });
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : String(err);
    console.error("[b2Delete] Error:", message);
    res.status(500).json({ error: "b2Delete failed" });
  }
});

export default router;
