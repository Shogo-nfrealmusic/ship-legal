# Recipe: rate-limit sign-in, sign-up and password reset

Goal: slow down password guessing and account spam on endpoints your own code runs.
Hosted auth (Supabase Auth, Firebase Auth, Clerk, Auth0) rate-limits its own endpoints:
N/A there.

## Done when
- Login, sign-up, password-reset and OTP endpoints allow ~5-10 attempts per IP (and per
  account/email) per 15 minutes, then return 429 with a Retry-After header.
- Passwords are stored with a slow hash (bcrypt/argon2/scrypt), not plain SHA-256/MD5 —
  if you find a fast hash, switch to a slow one with a fallback that re-hashes on next
  login, and say so.

## Stack notes
- Express: `express-rate-limit`. Next.js / serverless: `@upstash/ratelimit` (needs Upstash
  env → Human TODO) or a simple in-memory limiter with a comment that it's per-instance.
- FastAPI: `slowapi` (`Limiter(key_func=get_remote_address)`, `@limiter.limit("5/minute")`)
  or a small in-memory dict limiter if adding a dependency isn't approved; Flask:
  `Flask-Limiter`; Django: `django-ratelimit`; Rails: `rack-attack`.
- Password hashing: Python `passlib[bcrypt]` / `bcrypt` or stdlib `hashlib.scrypt`;
  Node `bcrypt`/`argon2`; Rails `has_secure_password`.
New dependency → add it to package.json/requirements/Gemfile and say an install is needed.
