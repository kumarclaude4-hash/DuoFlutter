const express = require('express');
const { requireAuth } = require('../middleware/auth');

const router = express.Router();

// Allowed protocols — only fetch http/https URLs
const ALLOWED_PROTOCOLS = ['http:', 'https:'];

// Maximum response size to read (1MB) — prevent memory abuse
const MAX_BYTES = 1_000_000;

// Timeout for fetching external URLs
const FETCH_TIMEOUT_MS = 8_000;

/**
 * Extracts Open Graph / meta tags from an HTML string.
 */
function extractMeta(html) {
  const ogTitle = html.match(/<meta[^>]+property=["']og:title["'][^>]+content=["']([^"']+)["']/i)?.[1]
    || html.match(/<meta[^>]+content=["']([^"']+)["'][^>]+property=["']og:title["']/i)?.[1];

  const ogDescription = html.match(/<meta[^>]+property=["']og:description["'][^>]+content=["']([^"']+)["']/i)?.[1]
    || html.match(/<meta[^>]+content=["']([^"']+)["'][^>]+property=["']og:description["']/i)?.[1];

  const ogImage = html.match(/<meta[^>]+property=["']og:image["'][^>]+content=["']([^"']+)["']/i)?.[1]
    || html.match(/<meta[^>]+content=["']([^"']+)["'][^>]+property=["']og:image["']/i)?.[1];

  const metaDescription = html.match(/<meta[^>]+name=["']description["'][^>]+content=["']([^"']+)["']/i)?.[1]
    || html.match(/<meta[^>]+content=["']([^"']+)["'][^>]+name=["']description["']/i)?.[1];

  const titleTag = html.match(/<title[^>]*>([^<]+)<\/title>/i)?.[1];

  return {
    title: ogTitle || titleTag || null,
    description: ogDescription || metaDescription || null,
    image: ogImage || null,
  };
}

/**
 * POST /linkPreview
 * Body: { url: string }
 * Response: { title: string|null, description: string|null, image: string|null }
 *
 * Fetches the URL server-side and extracts OG/meta tags.
 * Server-side fetch avoids CORS issues on mobile clients.
 */
router.post('/linkPreview', requireAuth, async (req, res) => {
  const { url } = req.body;

  if (!url || typeof url !== 'string') {
    return res.status(400).json({ error: 'url is required' });
  }

  let parsed;
  try {
    parsed = new URL(url);
  } catch {
    return res.status(400).json({ error: 'Invalid URL' });
  }

  if (!ALLOWED_PROTOCOLS.includes(parsed.protocol)) {
    return res.status(400).json({ error: 'Only http/https URLs are allowed' });
  }

  // Block private/local addresses (SSRF protection)
  const hostname = parsed.hostname.toLowerCase();
  if (
    hostname === 'localhost' ||
    hostname === '127.0.0.1' ||
    hostname.startsWith('192.168.') ||
    hostname.startsWith('10.') ||
    hostname.startsWith('172.16.') ||
    hostname.endsWith('.local') ||
    hostname === '::1'
  ) {
    return res.status(400).json({ error: 'Private addresses not allowed' });
  }

  try {
    const { fetch } = await import('node-fetch');
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), FETCH_TIMEOUT_MS);

    const response = await fetch(url, {
      signal: controller.signal,
      headers: {
        'User-Agent': 'DuoShieldBot/1.0 (+https://duoshield.app)',
        'Accept': 'text/html,application/xhtml+xml',
        'Accept-Language': 'en-US,en;q=0.9',
      },
      redirect: 'follow',
      size: MAX_BYTES,
    });

    clearTimeout(timer);

    const contentType = response.headers.get('content-type') || '';
    if (!contentType.includes('text/html')) {
      return res.json({ title: null, description: null, image: null });
    }

    let html = '';
    const reader = response.body;
    let bytesRead = 0;
    for await (const chunk of reader) {
      bytesRead += chunk.length;
      html += chunk.toString('utf8');
      // Stop once we have the <head> section (usually first 50KB is enough)
      if (bytesRead > 50_000 || html.includes('</head>')) break;
    }

    const meta = extractMeta(html);
    console.log('[linkPreview] Fetched:', url, '→ title:', meta.title);
    return res.json(meta);
  } catch (err) {
    if (err.name === 'AbortError') {
      console.warn('[linkPreview] Timeout fetching:', url);
      return res.json({ title: null, description: null, image: null });
    }
    console.error('[linkPreview] Error:', err.message);
    return res.json({ title: null, description: null, image: null });
  }
});

module.exports = router;
