// Simple per-instance rate limit: 5 attempts per IP per 15 minutes.
const hits = new Map<string, { count: number; reset: number }>();

export function rateLimited(req: Request, limit = 5, windowMs = 15 * 60 * 1000): boolean {
  const ip = req.headers.get("x-forwarded-for")?.split(",")[0]?.trim() ?? "unknown";
  const now = Date.now();
  const h = hits.get(ip);
  if (!h || h.reset < now) {
    hits.set(ip, { count: 1, reset: now + windowMs });
    return false;
  }
  h.count += 1;
  return h.count > limit;
}
