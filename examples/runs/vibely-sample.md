# Next.js (v1 sample, v2 skill)

Prompt: `/legal-check` → `yes`

## Turn 1

Duration 61 s · cost $0.71 at API list prices · 19 tool calls

```
legal-check · vibely · next (no backend)
13 RISK (2 High) · 1 CHECK · 3 PASS · 7 N/A

 ID  Risk    Check                               Where
 S3  High    Admin area without auth             app/api/waitlist/launch/route.ts:7
 P1  High    Session replay (CIPA)               app/providers.tsx:15
 S5  Medium  Login rate limits & hashing         lib/db.ts:39
 P3  Medium  Analytics cookies (EU consent)      app/providers.tsx:9
 P5  Medium  Privacy policy & terms              (no /privacy, /terms)
 P6  Medium  Account deletion & data export      app/settings/profile/page.tsx
 K1  Medium  Kids under 13 (COPPA)               app/signup/page.tsx:28
 M1  Medium  Marketing email (CAN-SPAM)          emails/launch-announcement.ts:5
 $1  Medium  Subscriptions (CA auto-renewal)     app/pricing/page.tsx:19
 C1  Medium  User uploads (DMCA)                 app/api/avatar/route.ts:11
 C2  Medium  Report & block for user content     app/u/[handle]/page.tsx:9
 P4  Low     Google Fonts from Google (GDPR)     app/layout.tsx:17
 $2  Low     Refund policy & price clarity       app/pricing/page.tsx
CHECK  A1 Contrast only spot-checked (footer #777 on #fafafa is borderline)
PASS   S1 Secrets · S4 Card data (Stripe Checkout) · A1 alt/labels/lang
N/A    S2 Database · P2 Ad pixels · P7 Do Not Sell · K2 Age rating · M2 SMS
       M3 Testimonials · C3 Trademarks · C4 AI

── S3 · High · Admin area without auth
Found: app/api/waitlist/launch/route.ts:7 — anyone can POST and mail the whole waitlist
Risk:  A bulk-send route without a server-side check is open to anyone who finds it.
Fix:   Require an admin secret from env (constant-time compare), else 401.

── P1 · High · Session replay (CIPA)
Found: app/providers.tsx:15 — PostHog replay on load with maskAllInputs: false
Risk:  California's wiretap law (§631; $5,000 per violation under §637.2) is used in
       suits over session recording; here typed text is recorded, before any consent.
Fix:   Drop maskAllInputs:false; init PostHog only after "Accept" in a consent banner.

── S5 · Medium · Login rate limits & hashing
Found: lib/db.ts:39 — passwords hashed with plain SHA-256; /api/signup has no limit
Risk:  Not a law by itself: fast hashes and unlimited attempts lead to account takeover.
Fix:   Switch to scrypt (Node built-in) and add a per-IP limiter on /api/signup.

── P3 · Medium · Analytics cookies (EU consent)
Found: app/providers.tsx:9 — PostHog (sets cookies) initialises on every page load
Risk:  In the EU, non-essential cookies need prior consent; a pre-ticked box isn't
       consent (Planet49, 2019).
Fix:   Same consent banner as P1: Accept/Decline equal, choice saved, footer link.

── P5 · Medium · Privacy policy & terms
Found: no /privacy or /terms page or link; sign-up collects name, email, password
Risk:  CalOPPA requires a posted privacy policy; terms only bind users who clearly agree.
Fix:   Draft /privacy and /terms from the code, footer links, clickwrap on sign-up.

── P6 · Medium · Account deletion & data export
Found: app/settings/profile/page.tsx — accounts exist, no delete or export path
Risk:  GDPR (erasure, portability) and CCPA (delete) give users these rights.
Fix:   Add "Download my data" and "Delete my account" (confirm) + API routes.

── K1 · Medium · Kids under 13 (COPPA)
Found: app/signup/page.tsx:28 — social app (public profiles) with no age screen
Risk:  COPPA applies to child-directed services or actual knowledge of under-13 users
       ($53,088 per violation). General-audience apps needn't check ages, but a neutral
       screen avoids collecting data from kids you'd then know about.
Fix:   Neutral birth month/year on sign-up, checked server-side; under-13 stores nothing.

── M1 · Medium · Marketing email (CAN-SPAM)
Found: emails/launch-announcement.ts:5 — promo email (code EARLYVIBE), no unsubscribe
       or postal address
Risk:  Commercial email needs a working opt-out and a postal address; up to $53,088/email.
Fix:   Signed unsubscribe link + List-Unsubscribe headers, address from env (throws if unset).

── $1 · Medium · Subscriptions (CA auto-renewal)
Found: app/pricing/page.tsx:19 — "Go Pro" with no renewal terms, consent, or cancel path
Risk:  California requires renewal terms next to the button, affirmative consent, and
       easy online cancellation (§17602, as amended by AB 2863).
Fix:   Terms + unchecked checkbox by the button, server rejects without it, portal route.

── C1 · Medium · User uploads (DMCA)
Found: app/api/avatar/route.ts:11 — public avatar uploads shown on /u/[handle]
Risk:  Safe harbor needs a registered DMCA agent with contact info on the site.
Fix:   Add a /dmca draft page (agent details as TODO), link from footer and terms.

── C2 · Medium · Report & block for user content
Found: app/u/[handle]/page.tsx:9 — public profiles with no report or block
Risk:  Apple requires report/block for UGC; TAKE IT DOWN Act 48-hour removal applies.
Fix:   Report + block buttons on profiles, API routes, report contact in terms.

── P4 · Low · Google Fonts from Google (GDPR)
Found: app/layout.tsx:17 — Inter loaded from fonts.googleapis.com
Risk:  A German court awarded €100 to one visitor whose IP went to Google this way.
Fix:   Switch to next/font/google (self-hosted at build time).

── $2 · Low · Refund policy & price clarity
Found: app/pricing/page.tsx — subscription sold, no refund/cancellation policy
Risk:  Stripe's website checklist expects clear refund and cancellation policies.
Fix:   Add a /refunds page (window as TODO), linked in footer and by checkout.

I can fix in code: S3 P1 S5 P3 P5 P6 K1 M1 $1 C1 C2 P4 $2. Needs a human: register
DMCA agent, real postal address, Stripe portal cancellation, lawyer reviews policies.
Not legal advice — an automated check of common traps, not a full legal review.

Apply the code fixes? (yes / no / only some IDs, e.g. "S1 S2 A1")
```

## Turn 2

Duration 307 s · cost $1.91 at API list prices · 37 tool calls

Applying the fixes now. I'm starting with consent and replay, then fonts and the footer.

Consent + replay (P1, P3):

Now the server-side pieces: hashing, rate limit, age screen, the admin guard, and email.

Next: subscriptions, account deletion/export, and report/block.

Now the draft legal pages and the env vars.

Verifying: I'll search for leftovers, then run typecheck and build.

I applied all 13 fixes. Typecheck and build both pass.

```
Applied
 ✓ S3  /api/waitlist/launch now returns 401 unless Authorization: Bearer ADMIN_API_SECRET
 ✓ P1  maskAllInputs:false removed; PostHog only starts after Accept (providers.tsx)
 ✓ P3  Consent banner with equal Accept/Decline buttons, choice saved, "Cookie settings" in
       footer (consent-banner.tsx, lib/consent.ts, site-footer.tsx)
 ✓ S5  scrypt replaces SHA-256; verifyPassword still reads old hashes and flags them for
       re-hash; in-memory limit of 5 per 15 min per IP and per email on /api/signup, 429
       + Retry-After (lib/db.ts, lib/rate-limit.ts)
 ✓ P5  Draft /privacy and /terms built from what the code does; footer links; "By signing
       up you agree…" next to the sign-up button
 ✓ P6  "Download my data" (JSON) and "Delete my account" (deletes user, avatar blob, blocks)
       in settings (api/account, api/account/export)
 ✓ K1  Neutral birth month/year on sign-up (no year pre-selected), checked on the server;
       under 13 gets a neutral message, nothing is stored, and a 24h cookie blocks retries;
       only is13Plus is stored
 ✓ M1  Launch email footer has a signed unsubscribe link and a postal address from env;
       adds List-Unsubscribe headers and skips unsubscribed addresses; /unsubscribe page
       asks for a click and the POST route also handles one-click unsubscribe
 ✓ $1  Renewal terms and an unchecked checkbox by "Go Pro"; server rejects checkout
       without consent; terms repeated on Stripe Checkout; "Manage or cancel subscription"
       goes to the Stripe Customer Portal
 ✓ C1  Draft /dmca page (agent details from env), linked from footer and terms
 ✓ C2  Report and Block buttons on public profiles; blocked profiles are hidden; reports
       are stored with no route that exposes them
 ✓ P4  Inter now loads through next/font/google (self-hosted); no Google Fonts URLs left
 ✓ $2  Draft /refunds page linked in footer and next to checkout
Checks: npm run typecheck → pass, npm run build → pass (18 pages)

Human TODO (code can't do these)
 [ ] Set env vars in your host: ADMIN_API_SECRET, UNSUBSCRIBE_SECRET,
     COMPANY_POSTAL_ADDRESS, CONTACT_EMAIL, LEGAL_EFFECTIVE_DATE, DMCA_AGENT_NAME,
     DMCA_AGENT_ADDRESS, DMCA_AGENT_PHONE, DMCA_AGENT_EMAIL (legal pages and the launch
     email throw in production until they're set)
 [ ] Put your real postal address in COMPANY_POSTAL_ADDRESS (CAN-SPAM); honor opt-outs
     within 10 business days and keep links working for at least 30 days
 [ ] Register a DMCA agent at dmca.copyright.gov ($6, renew every 3 years); copy the
     exact details into the DMCA_AGENT_* vars
 [ ] Turn on cancellation in the Stripe Customer Portal settings
 [ ] Save stripeCustomerId from a checkout.session.completed webhook; until then the
     "Manage or cancel subscription" button returns "No subscription found"
 [ ] Fill the TODO(legal-check) comments: company name, when a cancellation takes
     effect, refund window, records you must keep, governing law
 [ ] The app has no real auth yet (currentUserId() is a stub): account delete/export,
     billing portal, report and block stay unprotected until real sessions exist
 [ ] Rate limiter is per server instance and trusts X-Forwarded-For (fine on Vercel);
     use a shared store like Upstash if you run more than one instance
 [ ] No login route exists yet; when you add one, rate-limit failed attempts and call
     verifyPassword, re-hashing when needsRehash is true
 [ ] Decide who reviews reports and how fast (TAKE IT DOWN Act: 48h for intimate images)
 [ ] Check replay masking in the PostHog dashboard
 [ ] Run Lighthouse or axe and a keyboard-only pass; check footer text contrast
 [ ] Write a one-page breach plan: who decides, who you notify, and by when
 [ ] Decide whether the app is directed to children; if yes, talk to a lawyer first
 [ ] Have a lawyer review the privacy policy, terms, refund, renewal, and DMCA pages

Not legal advice. This checked common traps with automated pattern matching and may
miss things. Have a lawyer review your policies and flows before you rely on them.
```
