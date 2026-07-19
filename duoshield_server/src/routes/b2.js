const express = require('express');
const { S3Client, DeleteObjectCommand } = require('@aws-sdk/client-s3');
const { getSignedUrl } = require('@aws-sdk/s3-request-presigner');
const { PutObjectCommand, GetObjectCommand } = require('@aws-sdk/client-s3');
const { requireAuth } = require('../middleware/auth');

const router = express.Router();

const B2_KEY_ID = process.env.B2_KEY_ID;
const B2_APPLICATION_KEY = process.env.B2_APPLICATION_KEY;
const B2_BUCKET_NAME = process.env.B2_BUCKET_NAME;
const B2_ENDPOINT = process.env.B2_ENDPOINT;
const B2_PRESIGN_TTL = parseInt(process.env.B2_PRESIGN_TTL || '3600', 10);

function getS3Client() {
  if (!B2_KEY_ID || !B2_APPLICATION_KEY || !B2_ENDPOINT) {
    throw new Error('B2 credentials not configured');
  }
  return new S3Client({
    endpoint: B2_ENDPOINT,
    region: 'us-east-1',
    credentials: {
      accessKeyId: B2_KEY_ID,
      secretAccessKey: B2_APPLICATION_KEY,
    },
    forcePathStyle: true,
  });
}

/**
 * POST /b2PresignedPut
 * Body: { key: string, contentType: string }
 * Response: { url: string, objectKey: string }
 *
 * Generates a presigned PUT URL for uploading encrypted media to B2.
 * The Flutter client encrypts the file with AES-256-GCM before uploading.
 */
router.post('/b2PresignedPut', requireAuth, async (req, res) => {
  const { key, contentType } = req.body;

  if (!key || !contentType) {
    return res.status(400).json({ error: 'key and contentType are required' });
  }

  // Validate key to prevent path traversal
  if (!/^[\w\-./]+$/.test(key)) {
    return res.status(400).json({ error: 'Invalid key format' });
  }

  try {
    const client = getS3Client();
    const command = new PutObjectCommand({
      Bucket: B2_BUCKET_NAME,
      Key: key,
      ContentType: contentType,
    });

    const url = await getSignedUrl(client, command, { expiresIn: B2_PRESIGN_TTL });
    console.log('[b2PresignedPut] Generated PUT URL for key:', key);
    return res.json({ url, objectKey: key });
  } catch (err) {
    console.error('[b2PresignedPut] Error:', err.message);
    return res.status(500).json({ error: 'b2PresignedPut failed' });
  }
});

/**
 * POST /b2PresignedGet
 * Body: { key: string }
 * Response: { url: string }
 *
 * Generates a presigned GET URL for downloading encrypted media from B2.
 */
router.post('/b2PresignedGet', requireAuth, async (req, res) => {
  const { key } = req.body;

  if (!key) {
    return res.status(400).json({ error: 'key is required' });
  }

  if (!/^[\w\-./]+$/.test(key)) {
    return res.status(400).json({ error: 'Invalid key format' });
  }

  try {
    const client = getS3Client();
    const command = new GetObjectCommand({
      Bucket: B2_BUCKET_NAME,
      Key: key,
    });

    const url = await getSignedUrl(client, command, { expiresIn: B2_PRESIGN_TTL });
    console.log('[b2PresignedGet] Generated GET URL for key:', key);
    return res.json({ url });
  } catch (err) {
    console.error('[b2PresignedGet] Error:', err.message);
    return res.status(500).json({ error: 'b2PresignedGet failed' });
  }
});

/**
 * POST /b2Delete
 * Body: { key: string }
 * Response: { success: true }
 *
 * Deletes an object from B2. Called when a message is deleted for everyone.
 */
router.post('/b2Delete', requireAuth, async (req, res) => {
  const { key } = req.body;

  if (!key) {
    return res.status(400).json({ error: 'key is required' });
  }

  if (!/^[\w\-./]+$/.test(key)) {
    return res.status(400).json({ error: 'Invalid key format' });
  }

  try {
    const client = getS3Client();
    const command = new DeleteObjectCommand({
      Bucket: B2_BUCKET_NAME,
      Key: key,
    });

    await client.send(command);
    console.log('[b2Delete] Deleted key:', key);
    return res.json({ success: true });
  } catch (err) {
    console.error('[b2Delete] Error:', err.message);
    return res.status(500).json({ error: 'b2Delete failed' });
  }
});

module.exports = router;
