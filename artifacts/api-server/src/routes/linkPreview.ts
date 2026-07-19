import { Router } from "express";
import { requireAuth, type AuthedRequest } from "../middlewares/requireAuth.js";

const router = Router();

const ALLOWED_PROTOCOLS = ["http:", "https:"];
const MAX_BYTES = 1_000_000;
const FETCH_TIMEOUT_MS = 8_000;

interface MetaTags {
  title: string | null;
  description: string | null;
  image: string | null;
}

function extractMeta(html: string): MetaTags {
  const ogTitle =
    html.match(
      /<meta[^>]+property=["']og:title["'][^>]+content=["']([^"']+)["']/i
    )?.[1] ||
    html.match(
      /<meta[^>]+content=["']([^"']+)["'][^>]+property=["']og:title["']/i
    )?.[1];

  const ogDescription =
    html.match(
      /<meta[^>]+property=["']og:description["'][^>]+content=["']([^"']+)["']/i
    )?.[1] ||
    html.match(
      /<meta[^>]+content=["']([^"']+)["'][^>]+property=["']og:description["']/i
    )?.[1];

  const ogImage =
    html.match(
      /<meta[^>]+property=["']og:image["'][^>]+content=["']([^"']+)["']/i
    )?.[1] ||
    html.match(
      /<meta[^>]+content=["']([^"']+)["'][^>]+property=["']og:image["']/i
    )?.[1];

  const metaDescription =
    html.match(
      /<meta[^>]+name=["']description["'][^>]+content=["']([^"']+)["']/i
    )?.[1] ||
    html.match(
      /<meta[^>]+content=["']([^"']+)["'][^>]+name=["']description["']/i
    )?.[1];

  const titleTag = html.match(/<title[^>]*>([^<]+)<\/title>/i)?.[1];

  return {
    title: ogTitle ?? titleTag ?? null,
    description: ogDescription ?? metaDescription ?? null,
    image: ogImage ?? null,
  };
}

/**
 * POST /api/linkPreview
 * Body: { url: string }
 * Response: { title, description, image }
 */
router.post("/linkPreview", requireAuth, async (_req: AuthedRequest, res) => {
  const { url } = _req.body as { url?: string };

  if (!url || typeof url !== "string") {
    res.status(400).json({ error: "url is required" });
    return;
  }

  let parsed: URL;
  try {
    parsed = new URL(url);
  } catch {
    res.status(400).json({ error: "Invalid URL" });
    return;
  }

  if (!ALLOWED_PROTOCOLS.includes(parsed.protocol)) {
    res.status(400).json({ error: "Only http/https URLs are allowed" });
    return;
  }

  const hostname = parsed.hostname.toLowerCase();
  if (
    hostname === "localhost" ||
    hostname === "127.0.0.1" ||
    hostname.startsWith("192.168.") ||
    hostname.startsWith("10.") ||
    hostname.startsWith("172.16.") ||
    hostname.endsWith(".local") ||
    hostname === "::1"
  ) {
    res.status(400).json({ error: "Private addresses not allowed" });
    return;
  }

  try {
    const { default: fetch } = await import("node-fetch");
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), FETCH_TIMEOUT_MS);

    const response = await fetch(url, {
      signal: controller.signal as AbortSignal,
      headers: {
        "User-Agent": "DuoShieldBot/1.0 (+https://duoshield.app)",
        Accept: "text/html,application/xhtml+xml",
        "Accept-Language": "en-US,en;q=0.9",
      },
      redirect: "follow",
      size: MAX_BYTES,
    } as Parameters<typeof fetch>[1]);

    clearTimeout(timer);

    const contentType = response.headers.get("content-type") ?? "";
    if (!contentType.includes("text/html")) {
      res.json({ title: null, description: null, image: null });
      return;
    }

    let html = "";
    let bytesRead = 0;
    for await (const chunk of response.body as AsyncIterable<Buffer>) {
      bytesRead += chunk.length;
      html += chunk.toString("utf8");
      if (bytesRead > 50_000 || html.includes("</head>")) break;
    }

    const meta = extractMeta(html);
    console.log("[linkPreview] Fetched:", url, "→ title:", meta.title);
    res.json(meta);
  } catch (err: unknown) {
    if ((err as { name?: string }).name === "AbortError") {
      console.warn("[linkPreview] Timeout fetching:", url);
      res.json({ title: null, description: null, image: null });
      return;
    }
    const message = err instanceof Error ? err.message : String(err);
    console.error("[linkPreview] Error:", message);
    res.json({ title: null, description: null, image: null });
  }
});

export default router;
