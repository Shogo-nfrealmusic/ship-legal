# FastAPI + Jinja (Replit)

Prompt: `/legal-check` → `yes`

## Turn 1

Duration 43 s · cost $0.64 at API list prices · 11 tool calls

```
legal-check · fastapi · fastapi (+ replit)
12 RISK (3 High) · 0 CHECK · 1 PASS · 11 N/A

 ID  Risk    Check                               Where
 S1  High    Secret keys exposed                 app/config.py:2
 S3  High    Admin area without auth             app/main.py:82
 S4  High    Card data on your server (PCI)      app/main.py:60
 S5  Medium  Login rate limits & hashing         app/main.py:26
 P5  Medium  Privacy policy & terms              app/templates/base.html:11
 P6  Medium  Account deletion & data export      app/main.py:39
 M1  Medium  Marketing email (CAN-SPAM)          app/emailer.py:6
 C1  Medium  User uploads (DMCA)                 app/templates/gallery.html:4
 C2  Medium  Report & block for user content     app/templates/gallery.html:4
 A1  Medium  Accessibility basics (ADA/WCAG)     app/templates/index.html:4
 P4  Low     Google Fonts from Google (GDPR)     app/templates/base.html:6
 $2  Low     Refund policy & price clarity       app/main.py:66
CHECK  (none)
PASS   K1 Kids (general-audience print shop; age screen optional)
N/A    S2 Database · P1 Replay · P2 Ad pixels · P3 Analytics · P7 Do Not Sell ·
       K2 Age rating · M2 SMS · M3 Testimonials · $1 Subscriptions · C3 Trademarks ·
       C4 AI

── S1 · High · Secret keys exposed
Found: app/config.py:2-3 — live Stripe secret key and Mailgun key hard-coded in git
Risk:  Anything pushed to git can be read by anyone; leaked keys run up bills and
       expose user data. The FTC treats weak data security as an unfair practice.
Fix:   Read both keys from env vars, fail fast if missing, add .env.example.

── S3 · High · Admin area without auth
Found: app/main.py:82 — GET /admin/orders returns every order with no auth check
Risk:  An admin URL without a server-side check is open to anyone who finds it
       (here: every stored card number and CVC).
Fix:   HTTP Basic with credentials from env on admin routes (stopgap; no sessions yet).

── S4 · High · Card data on your server (PCI)
Found: app/main.py:60-70 — card number, expiry and CVC posted to you and stored in SQLite
Risk:  Raw cards on your server mean far more PCI DSS work; storing the CVC after
       authorization is never allowed. Stripe Checkout keeps cards on Stripe (SAQ A).
Fix:   Replace card inputs with Stripe Checkout; drop card columns; add stripe dep.

── S5 · Medium · Login rate limits & hashing
Found: app/main.py:26 — passwords hashed with unsalted SHA-256; login/signup unlimited
Risk:  Not a law by itself: unlimited guesses and fast hashes are how accounts get
       taken over, which becomes a breach.
Fix:   scrypt hashing with re-hash on login; in-memory per-IP limiter returning 429.

── P5 · Medium · Privacy policy & terms
Found: app/templates/base.html:11 — no /privacy or /terms page, footer links nothing
Risk:  CalOPPA requires a posted privacy policy for sites collecting personal info
       from Californians. Terms only bind users who clearly agree (clickwrap).
Fix:   Draft /privacy and /terms from the code, footer links, clickwrap at sign-up/order.

── P6 · Medium · Account deletion & data export
Found: app/main.py:39 — accounts are created; no way to delete or export them
Risk:  GDPR (erasure, portability) and CCPA (delete) give users these rights.
Fix:   Add delete-account and download-my-data routes (need real sessions; see TODO).

── M1 · Medium · Marketing email (CAN-SPAM)
Found: app/emailer.py:6 — "40% off" promo sent on sign-up, no unsubscribe or address
Risk:  Commercial email needs a working opt-out and a valid postal address;
       penalties reach $53,088 per email.
Fix:   Signed unsubscribe link + List-Unsubscribe headers, address from env, skip opt-outs.

── C1 · Medium · User uploads (DMCA)
Found: app/templates/gallery.html:4 — every uploaded artwork is shown publicly
Risk:  To keep DMCA safe harbor for uploads you need a registered agent and their
       contact info posted; Section 230 doesn't cover IP claims.
Fix:   Add a /dmca draft page, link it in the footer and terms.

── C2 · Medium · Report & block for user content
Found: app/templates/gallery.html:4 — public gallery with no report option or contact
Risk:  Since 19 May 2026, platforms mainly hosting user content must remove NCII
       within 48 hours of a valid request; reporting is expected for UGC.
Fix:   "Report" per gallery image stored in a reports table; published report contact.

── A1 · Medium · Accessibility basics (ADA/WCAG)
Found: app/templates/index.html:4 — images without alt, inputs with no labels
Risk:  About 3,100 federal ADA website suits were filed in 2025; WCAG 2.1 AA is the
       usual yardstick. Contrast here is only spot-checked.
Fix:   Add alt text and visible labels in index, signup and gallery templates.

── P4 · Low · Google Fonts from Google (GDPR)
Found: app/templates/base.html:6 — Lora loaded from fonts.googleapis.com
Risk:  A German court awarded a visitor €100 because a site sent his IP to Google via
       Google Fonts. Matters if you have EU visitors.
Fix:   Self-host Lora via @font-face in static/fonts.

── $2 · Low · Refund policy & price clarity
Found: app/main.py:66 — $4.99 service fee added after the advertised price; no refunds page
Risk:  California bans advertised prices that leave out mandatory fees; Stripe expects
       a clear refund and cancellation policy.
Fix:   Show prices including the fee; add a /refunds draft page linked near checkout.

I can fix in code: S1 S3 S4 S5 P5 P6 M1 C1 C2 A1 P4 $2. Needs a human: rotate
both keys, delete stored card data, register DMCA agent, real postal address,
download Lora font files, lawyer review of pages.
Not legal advice — an automated check of common traps, not a full legal review.

Apply the code fixes? (yes / no / only some IDs, e.g. "S1 S2 A1")
```

## Turn 2

Duration 194 s · cost $1.49 at API list prices · 28 tool calls

Backend changes are in. Next: the templates (legal pages, labels, footer links) and the font CSS.

Now the draft legal pages.

Verifying: searching for anything the fixes should have removed.

Only the intentional legacy-hash check remains (needed to upgrade old hashes on login). Running tests:

I made all 12 fixes. The 2 existing tests pass, but they only cover the home page and sign-up. I didn't run the new Stripe checkout, the account routes or the unsubscribe routes, and `stripe` isn't installed yet.

```
Applied
 ✓ S1  Stripe/Mailgun keys now come from env vars (app/config.py); error in prod if
       missing; .env.example added; .env added to .gitignore
 ✓ S3  /admin/orders and /admin/reports need HTTP Basic (ADMIN_USERNAME/PASSWORD from
       env); 503 if unset. Stopgap, since the app has no sessions (app/main.py)
 ✓ S4  Card inputs removed; /order now redirects to Stripe Checkout; card columns
       dropped from schema; migrations/001_remove_card_data.sql written (not run)
 ✓ S5  Passwords now hashed with salted scrypt; old SHA-256 hashes upgraded on next
       login; in-memory limiter: 10 failed logins per IP and per email / 15 min,
       10 sign-ups per IP; returns 429 + Retry-After
 ✓ P5  Draft /privacy and /terms pages; footer links on every page; "you agree"
       text at sign-up and order
 ✓ P6  /account: delete account and download data (JSON); both re-check email +
       password
 ✓ M1  Promo email: signed unsubscribe link (GET shows confirm, POST unsubscribes,
       one-click headers), postal address footer, skips unsubscribed addresses;
       refuses to send in prod without PUBLIC_BASE_URL / COMPANY_POSTAL_ADDRESS
 ✓ C1  Draft /dmca page (agent details from DMCA_AGENT_* env), linked from footer,
       terms and gallery
 ✓ C2  "Report" form on each gallery image → reports table; admins read them at
       /admin/reports; terms publish a report contact and the 48h NCII removal rule
 ✓ A1  Labels on all form fields, alt text on gallery images (hero image alt is a
       TODO), footer contrast fixed (#ccc → #595959), visible focus style
 ✓ P4  Google Fonts link removed; Lora now loads from /static/fonts via @font-face
 ✓ $2  Advertised prices include the $4.99 fee; draft /refunds page linked at checkout
Checks: .venv/bin/pytest -q → 2 passed.
        Search: no hard-coded keys, card fields or Google Fonts left.
        Stripe code not tested: stripe isn't installed and the tests don't cover it.

Human TODO (code can't do these)
 [ ] Rotate the Stripe secret key and Mailgun key now; they were committed to git,
     so treat them as leaked. Also clean them from git history
 [ ] Install the new dependency: .venv/bin/pip install -r requirements.txt (adds stripe)
 [ ] Run migrations/001_remove_card_data.sql on the real DB. Delete stored card
     numbers/CVCs, including any backups; never archive them.
     Until it runs, new orders on an old DB will fail
 [ ] Set env vars on your host (Replit Secrets): APP_ENV=production,
     STRIPE_SECRET_KEY, MAILGUN_API_KEY, UNSUBSCRIBE_SECRET, ADMIN_USERNAME,
     ADMIN_PASSWORD, PUBLIC_BASE_URL, COMPANY_POSTAL_ADDRESS, CONTACT_EMAIL,
     DMCA_AGENT_NAME/ADDRESS/PHONE/EMAIL
 [ ] Put your real postal address in COMPANY_POSTAL_ADDRESS (CAN-SPAM). Honor
     opt-outs within 10 business days; keep links working 30+ days
 [ ] Register a DMCA agent at dmca.copyright.gov ($6, renew every 3 years); copy
     the exact details into the DMCA_AGENT_* env vars
 [ ] Download Lora 400/700 .woff2 files into app/static/fonts/ (e.g. from
     google-webfonts-helper). Until then the browser uses a fallback serif font
 [ ] Fill the TODO(legal-check) items in privacy/terms/refunds (company name,
     dates, hosting/print partners, refund window, governing law, retention) and
     the hero image alt text
 [ ] Admin is HTTP Basic only (stopgap); add real sessions and an admin role.
     Orders aren't linked to user accounts (user_id is never set), so deletion
     and export only cover the user's own account row
 [ ] No block feature: uploads aren't tied to users. Decide who reviews
     /admin/reports and how fast (48h for intimate images)
 [ ] Rate limiter is per process and uses the direct client IP; behind Replit's
     proxy, run uvicorn with --proxy-headers or all users share one limit
 [ ] Consider a Stripe webhook to confirm payments; the success page alone is
     not reliable
 [ ] Run Lighthouse or axe and a keyboard-only pass
 [ ] Write a one-page breach plan (card data was stored): who decides, who you
     notify, and by when. Every US state has a breach-notification law
 [ ] Have a lawyer review the privacy policy, terms, refund and DMCA pages

Not legal advice. This checked common traps with automated pattern matching and may
miss things. Have a lawyer review your policies and flows before you rely on them.
```

**Not fixed: a security bug in the upload route.** `/order` saves the file under the name the user sends (`app/main.py:67`), so a crafted name like `../x` can write files outside the uploads folder. The check doesn't cover this. I can fix it if you want.

The Stripe and Cloudflare connectors need authorizing in your claude.ai connector settings. I didn't need them for this run.
