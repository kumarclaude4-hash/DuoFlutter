import { Router, type IRouter } from "express";
import rateLimit from "express-rate-limit";
import healthRouter from "./health.js";
import mintRouter from "./mint.js";
import chatRouter from "./chat.js";
import turnRouter from "./turn.js";
import b2Router from "./b2.js";
import linkPreviewRouter from "./linkPreview.js";

const router: IRouter = Router();

// Rate limiters
const mintLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 10,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: "Too many mint requests." },
});

const previewLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 30,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: "Too many link preview requests." },
});

router.use(healthRouter);
router.use(mintLimiter, mintRouter);
router.use(chatRouter);
router.use(turnRouter);
router.use(b2Router);
router.use(previewLimiter, linkPreviewRouter);

export default router;
