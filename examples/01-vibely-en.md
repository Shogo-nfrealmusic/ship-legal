# 01-vibely-en

Prompt: `/legal-check`  →  `yes`

## Turn 1

Wall time 35 s · cost $0.57 at API list prices · 13 tool calls

legal-check · vibely · 8 RISK · 0 PASS · 0 N/A

```
 #  Check                          Status  Where
 1  Kids under 13 (COPPA)          RISK    app/signup/page.tsx:28
 2  Google Fonts CDN (GDPR, EU)    RISK    app/layout.tsx:14
 3  Session replay (CIPA)          RISK    app/providers.tsx:15
 4  Marketing email (CAN-SPAM)     RISK    emails/launch-announcement.ts:4
 5  Subscriptions (CA auto-renew)  RISK    app/pricing/page.tsx:19
 6  User uploads (DMCA)            RISK    app/api/avatar/route.ts:11
 7  Privacy policy & terms         RISK    -
 8  Analytics consent              RISK    app/providers.tsx:9
```

**── 1 · Kids under 13 (COPPA) · RISK**
Found: `app/signup/page.tsx:28`. The sign-up form collects name, username and email and has no age screen.
Risk: COPPA applies when a service is aimed at children, or when you actually know a user is under 13. The penalty can reach $53,088 per violation. A general-audience app doesn't have to check ages. But Vibely is a social app with public profiles and daily posts, and kids do sign up for apps like that. A neutral age screen stops you collecting data from users you would then know are under 13.
Fix: Add birth month and year fields with no hint about the "right" answer. Check the age on the server and block under-13s without storing anything.

**── 2 · Google Fonts CDN (GDPR, EU) · RISK**
Found: `app/layout.tsx:14-18`. Inter is loaded from fonts.googleapis.com and fonts.gstatic.com.
Risk: A German court (LG München I, 20 Jan 2022) awarded one visitor €100 because loading Google Fonts sent his IP address to Google. This matters if you have EU visitors.
Fix: Switch to `next/font/google`, which serves the font from your own domain. Remove the CDN `<link>` tags.

**── 3 · Session replay (CIPA) · RISK**
Found: `app/providers.tsx:13-15`. PostHog recording is on with `maskAllInputs: false`. It starts on page load, and no policy discloses it.
Risk: Plaintiffs use California's wiretap law (Penal Code §631, with $5,000 per violation under §637.2) to sue over session recording. The "per session" math is their theory, not settled law. Right now, typed text such as names and emails gets recorded.
Fix: Turn default input masking back on, start PostHog only after the user accepts, and disclose the recording in `/privacy`.

**── 4 · Marketing email (CAN-SPAM) · RISK**
Found: `emails/launch-announcement.ts:4`. A promotional launch email with a promo code is sent to the whole waitlist. It has no unsubscribe link and no postal address.
Risk: CAN-SPAM (15 U.S.C. §7704) requires a working opt-out and a valid physical postal address in commercial email. The penalty can reach $53,088 per email.
Fix:
- Add a footer with a signed unsubscribe link and a placeholder address.
- Add an `/api/unsubscribe` route and `List-Unsubscribe` headers.
- Skip unsubscribed addresses when sending.

**── 5 · Subscriptions (CA auto-renewal) · RISK**
Found: `app/pricing/page.tsx:19`. The "Go Pro" button ($12/mo) has no renewal terms and no consent step. There is no online way to cancel.
Risk: California's Automatic Renewal Law (§17602, as amended by AB 2863) requires three things: clear renewal terms next to the button, affirmative consent, and easy online cancellation.
Fix:
- Put the renewal terms next to the button, with an unchecked checkbox that must be ticked before subscribing.
- Repeat the terms on Stripe Checkout.
- Add a billing-portal route and a "Manage or cancel" button.

**── 6 · User uploads (DMCA) · RISK**
Found: `app/api/avatar/route.ts:11`. Avatars are stored with public access and shown on public profiles. There is no DMCA page.
Risk: To keep DMCA safe harbor (§512(c)(2)) for user uploads, you need a designated agent registered with the Copyright Office, and the agent's contact details posted on your site.
Fix: Add a `/dmca` page with placeholder agent details, link it in the footer, and add an uploads clause to the terms.

**── 7 · Privacy policy & terms · RISK**
Found: There is no `/privacy` or `/terms` page and no footer links, yet the app collects emails, names and payment data.
Risk: California's CalOPPA requires a commercial site that collects personal information from California residents to post a privacy policy conspicuously. Terms aren't legally required, but they set the rules for user content and subscriptions.
Fix: Create draft `/privacy` and `/terms` pages that name PostHog, Resend, Stripe and Vercel Blob. Link them from every page.

**── 8 · Analytics consent · RISK**
Found: `app/providers.tsx:9`. `posthog.init` runs on every page load with no consent step.
Risk: In the EU and UK, trackers need prior consent. Most US states don't require a cookie banner, but consent is the main defense against wiretap claims (check 3).
Fix: Add a consent banner where Decline is as easy as Accept. PostHog only starts after Accept.

Fixes I can apply now: 1, 2, 3, 4, 5, 6, 7, 8.
Needs a human: a real postal address, env vars, DMCA agent registration, turning on cancellation in the Stripe portal, and a lawyer review.
Not legal advice. This is an automated check of 8 common traps, not a full legal review.

Apply the code fixes? (yes / no / only some numbers, e.g. "1 3")

## Turn 2

Wall time 155 s · cost $1.29 at API list prices · 33 tool calls

Fixes 1–5 and 8 are done. I'm now writing the /dmca, /privacy and /terms pages, and then I'll run the checks.

Add the new env vars to `.env.example`, then verify.

I applied all 8 fixes. Typecheck and build both pass, and a search confirms the Google Fonts CDN links are gone from source.

```
Applied
 ✓ 1  Neutral age screen: birth month/year at sign-up. Server blocks under-13s, stores
      nothing, sets a 24h cookie (app/signup/page.tsx, app/api/signup/route.ts)
 ✓ 2  Inter now served by next/font/google from your domain; CDN links removed
      (app/layout.tsx, app/globals.css)
 ✓ 3  PostHog input masking back to default; replay disclosed in /privacy
      (lib/analytics.ts, app/privacy/page.tsx)
 ✓ 4  Launch email: signed unsubscribe link, postal address, List-Unsubscribe headers,
      skips unsubscribed addresses (emails/launch-announcement.ts,
      app/api/waitlist/launch/route.ts, app/api/unsubscribe/route.ts,
      lib/unsubscribe.ts, lib/company.ts, lib/db.ts)
 ✓ 5  $12/mo renewal terms and an unchecked checkbox next to "Go Pro", also checked on
      the server; terms repeated on Stripe Checkout; "Manage or cancel subscription"
      button → Stripe portal (app/pricing/page.tsx, app/api/checkout/route.ts,
      app/api/billing-portal/route.ts, app/settings/profile/page.tsx)
 ✓ 6  /dmca draft with placeholder agent details; upload note and terms clause link to it
      (app/dmca/page.tsx)
 ✓ 7  /privacy and /terms drafts; footer links to Privacy, Terms and DMCA on every page
      (app/privacy, app/terms, app/layout.tsx)
 ✓ 8  Consent banner (Accept and Decline equally easy); PostHog starts only after Accept
      (app/consent-banner.tsx, app/providers.tsx)
Checks: search → no fonts.googleapis.com / fonts.gstatic.com and no maskAllInputs:false
        left in source; posthog.init only in acceptTracking()
        npm run typecheck → pass · npm run build → pass (16 routes); no lint script
```

**New env vars:** `UNSUBSCRIBE_SECRET` and `COMPANY_POSTAL_ADDRESS`, added to `.env.example`. `NEXT_PUBLIC_APP_URL` must now be set in production, because email links fail loudly instead of pointing at localhost. No new dependencies.

**Rules for the unsubscribe link:** opt-outs must be honored within 10 business days, and the link must keep working for at least 30 days after sending. The unsubscribe list lives in the in-memory store, like the rest of the sample app. In a real database it needs a new column and a migration.

**Cancel button:** it only works once the Stripe customer ID is saved after checkout, and the app never saves it yet. That needs a webhook handler; it's in the list below.

```
Human TODO (code can't do these)
 [ ] Put your real postal address in COMPANY_POSTAL_ADDRESS (CAN-SPAM)
 [ ] Set UNSUBSCRIBE_SECRET, COMPANY_POSTAL_ADDRESS, NEXT_PUBLIC_APP_URL in your host
 [ ] Register a DMCA designated agent at dmca.copyright.gov ($6, renew every 3 years)
     and copy the same details into /dmca
 [ ] Turn on cancellation in the Stripe Customer Portal settings
 [ ] Save stripeCustomerId from the checkout.session.completed webhook so the
     cancel button works for real subscribers
 [ ] Keep the $12/mo in the renewal terms in sync with STRIPE_PRICE_PRO in Stripe
 [ ] Check PostHog's session replay masking settings in its dashboard
 [ ] Decide whether the app is directed to children; if yes, talk to a lawyer about
     verifiable parental consent before launch
 [ ] Fill every TODO(legal-check) (entity name, contacts, dates, retention, law) and
     have a lawyer review the privacy policy, terms, renewal terms and DMCA page
```

Not legal advice. This checked 8 common traps with automated pattern matching and may miss things. Have a lawyer review your policies and flows before you rely on them.
