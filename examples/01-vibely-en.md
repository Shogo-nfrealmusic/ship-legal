# 01-vibely-en

Prompt: `/legal-check  →  yes`

## Turn 1

Wall time 37 s · cost $0.58 at API list prices · 13 tool calls

legal-check · vibely-en · 8 RISK · 0 PASS · 0 N/A

```
 #  Check                          Status  Where
 1  Kids under 13 (COPPA)          RISK    app/signup/page.tsx:29
 2  Google Fonts CDN (GDPR, EU)    RISK    app/layout.tsx:17
 3  Session replay (CIPA)          RISK    app/providers.tsx:15
 4  Marketing email (CAN-SPAM)     RISK    emails/launch-announcement.ts:8
 5  Subscriptions (CA auto-renew)  RISK    app/pricing/page.tsx:19
 6  User uploads (DMCA)            RISK    app/api/avatar/route.ts:11
 7  Privacy policy & terms         RISK    -
 8  Analytics consent              RISK    app/providers.tsx:9
```

── 1 · Kids under 13 (COPPA) · RISK
Found: app/signup/page.tsx:29 — the sign-up form asks for name, username, email and password, with no age screen.
Risk:  COPPA applies to services aimed at children under 13, or when you actually know
       a user is under 13 (up to $53,088 per violation). You don't have to check ages on a
       general-audience site. But Vibely is a social app with public profiles, so kids will
       sign up. A neutral age screen stops you collecting their data.
Fix:   Add birth month and year fields to sign-up, check the age on the server, don't store
       anything from under-13s, and set a 24h block cookie.

── 2 · Google Fonts CDN (GDPR, EU) · RISK
Found: app/layout.tsx:14-19 — every page loads Inter from fonts.googleapis.com.
Risk:  A German court (LG München I, 20 Jan 2022) awarded one visitor €100 because a site
       sent his IP address to Google this way. This matters if you have EU visitors.
Fix:   Switch to `next/font/google` (self-hosted at build time) and remove the CDN links.

── 3 · Session replay (CIPA) · RISK
Found: app/providers.tsx:13-15 — PostHog records sessions with `maskAllInputs: false`,
       starting on page load.
Risk:  Plaintiffs use California's wiretap law (§631; $5,000 per violation under §637.2)
       against session recording tools. The "per session" math is their theory, not
       settled law. Unmasked inputs, no consent and no disclosure make this app an easy
       target.
Fix:   Turn masking back on (PostHog default), start PostHog only after "Accept", and
       disclose it in /privacy.

── 4 · Marketing email (CAN-SPAM) · RISK
Found: emails/launch-announcement.ts:8 — the launch email is promotional (50% off code)
       and has no unsubscribe link or postal address.
Risk:  Under CAN-SPAM, commercial email needs a working opt-out and a valid postal address
       (up to $53,088 per email).
Fix:   Add a footer with a signed unsubscribe link and an address placeholder, an
       /api/unsubscribe route, List-Unsubscribe headers, and skip unsubscribed addresses.

── 5 · Subscriptions (CA auto-renewal) · RISK
Found: app/pricing/page.tsx:19 — "Go Pro" starts a $12/mo subscription with no renewal
       terms, no consent checkbox, and no way to cancel online.
Risk:  California's Automatic Renewal Law (§17602, as amended by AB 2863) requires clear
       renewal terms next to the button, affirmative consent, and easy online
       cancellation.
Fix:   Add the terms and an unchecked consent checkbox by the button, add `custom_text` in
       Checkout, and add a Stripe Customer Portal route with a "Manage or cancel" button.

── 6 · User uploads (DMCA) · RISK
Found: app/api/avatar/route.ts:11 — uploaded avatars are stored with `access: "public"`
       and shown on public profiles. There is no DMCA page.
Risk:  To keep DMCA §512(c) safe harbor for user uploads, you need a designated agent
       registered with the Copyright Office and their contact details posted on your site.
Fix:   Add a /dmca page with the agent details as placeholders, link it in the footer, and
       reference it in the terms.

── 7 · Privacy policy & terms · RISK
Found: No /privacy or /terms page exists, but the site collects emails, names and
       recordings.
Risk:  California's CalOPPA requires a commercial site that collects personal information
       from California residents to post a privacy policy where people can see it. Terms
       set the rules for uploads and subscriptions.
Fix:   Add draft /privacy and /terms pages based on what the code does, with footer links
       on every page.

── 8 · Analytics consent · RISK
Found: app/providers.tsx:9 — PostHog starts on every page load with no consent step.
Risk:  In the EU/UK, non-essential trackers need consent first. In the US, consent is the
       main defense against wiretap claims over recording (see check 3).
Fix:   Add a consent banner with equal Accept/Decline buttons. PostHog starts only on
       Accept. (This is the same change as check 3.)

Fixes I can apply now: 1 2 3 4 5 6 7 8.
Needs a human: real postal address, DMCA agent registration, Stripe Portal cancel setting,
saving the Stripe customer ID after checkout, env vars, and a lawyer's review.
Not legal advice. This is an automated check of 8 common traps, not a full legal review.

Apply the code fixes? (yes / no / only some numbers, e.g. "1 3")

## Turn 2

Wall time 146 s · cost $1.23 at API list prices · 30 tool calls

Applying all 8 fixes. First I'll read the files the fixes touch.

Next: the age screen and the email opt-out.

Now the renewal terms, the cancel path, and the policy and DMCA pages.

All fixes are written. Running the project's typecheck and build now.

I applied all 8 fixes. Typecheck and build both pass.

**Applied**
- ✓ **1 · Kids under 13:** sign-up now asks for birth month and year, with every year listed and none pre-selected. The server checks the age before anything is saved. Under-13s get a neutral "can't create an account" message and a 24-hour block cookie, and their data isn't stored. Files: `app/signup/page.tsx`, `app/api/signup/route.ts`.
- ✓ **2 · Google Fonts:** Inter now loads through `next/font/google`, which serves it from your own domain. I removed the Google CDN links and preconnects. Files: `app/layout.tsx`, `app/globals.css`.
- ✓ **3 and 8 · Session replay and consent:** I removed `maskAllInputs: false`, so PostHog's default input masking applies again. PostHog now starts only after the visitor clicks Accept, and the banner has an equally easy Decline button. Files: `lib/analytics.ts`, `app/consent-banner.tsx`, `app/providers.tsx`.
- ✓ **4 · Marketing email:**
  - The launch email now has a footer with a signed unsubscribe link and a postal address placeholder.
  - A new `/api/unsubscribe` route handles opt-outs. Opening the link (GET) only shows a confirm button; the POST does the unsubscribe.
  - Each email now carries `List-Unsubscribe` headers, and unsubscribed addresses are skipped when sending.
  - Files: `emails/launch-announcement.ts`, `app/api/waitlist/launch/route.ts`, `app/api/unsubscribe/route.ts`, `lib/unsubscribe.ts`, `lib/company.ts`, `lib/db.ts`.
- ✓ **5 · Subscriptions:**
  - The pricing page shows the renewal terms next to the button, and "Go Pro" stays disabled until an unchecked consent box is ticked. The server checks the consent too.
  - The Stripe Checkout page repeats the renewal terms.
  - There's a new `/api/billing-portal` route and a "Manage or cancel subscription" button in profile settings.
  - Files: `app/pricing/page.tsx`, `app/api/checkout/route.ts`, `app/api/billing-portal/route.ts`, `app/settings/profile/page.tsx`.
- ✓ **6 · DMCA:** new `/dmca` page with the takedown notice, counter-notice and repeat-infringer policy; the agent details are placeholders. It's linked in the footer and from the terms. File: `app/dmca/page.tsx`.
- ✓ **7 · Privacy and terms:** new draft `/privacy` and `/terms` pages based on what the code actually does: PostHog, Stripe, Resend and Vercel Blob. They're linked from the footer on every page. Files: `app/privacy/page.tsx`, `app/terms/page.tsx`.

**New env vars:** `UNSUBSCRIBE_SECRET` and `COMPANY_POSTAL_ADDRESS`, added to `.env.example`. I added no new dependencies.

**Before you use it:**
- **Cancel button:** it won't work yet. The app never saves the Stripe customer ID after checkout, so `/api/billing-portal` will return "No subscription found" until you do. It's marked with a `TODO(legal-check)` in the code.
- **Unsubscribe list:** it's in memory, like the rest of the sample store, so opt-outs are lost on restart. A real app needs it saved in a database.
- **Legal timing:** opt-outs must be honored within 10 business days, and the unsubscribe link must keep working for at least 30 days after each email.

**Checks:** `npm run typecheck` → passed, `npm run build` → passed (16 pages generated). The Grep tool wasn't available here, so I didn't do a separate search. I confirmed the fixes from the files I wrote instead. The Google Fonts links were only in `app/layout.tsx`, according to the scan, and I rewrote that file without them.

**Human TODO (code can't do these)**
- [ ] Put your real postal address in the email footer (CAN-SPAM).
- [ ] Set `UNSUBSCRIBE_SECRET`, `COMPANY_POSTAL_ADDRESS` and `NEXT_PUBLIC_APP_URL` in your host. Sending now fails in production if the app URL is missing.
- [ ] Register a DMCA designated agent at dmca.copyright.gov ($6, renew every 3 years) and copy the same details into the `/dmca` page.
- [ ] Turn on cancellation in the Stripe Customer Portal settings.
- [ ] Save `session.customer` from the `checkout.session.completed` webhook so the cancel button can find the customer.
- [ ] Keep the price in the renewal terms ($12/mo, in `app/pricing/page.tsx` and `app/api/checkout/route.ts`) in sync with the real price in Stripe.
- [ ] Check PostHog's masking settings in its dashboard.
- [ ] Decide whether the app is directed to children. If it is, talk to a lawyer about verifiable parental consent before launch.
- [ ] Fill in the `TODO(legal-check)` placeholders: company name, dates, retention periods, contact email, governing law.
- [ ] Have a lawyer review the privacy policy, terms, renewal terms, and DMCA page.

Not legal advice. This checked 8 common traps with automated pattern matching and may miss things. Have a lawyer review your policies and flows before you rely on them.
