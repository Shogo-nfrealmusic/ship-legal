# Plain HTML + Stripe Payment Link (Bolt export)

Prompt: `/legal-check` → `yes`

## Turn 1

Duration 38 s · cost $0.59 at API list prices · 5 tool calls

```
legal-check · html · static-html (builder: bolt)
11 RISK (4 High) · 3 CHECK · 2 PASS · 8 N/A

 ID  Risk    Check                               Where
 S1  High    Secret keys exposed                 js/app.js:2
 P1  High    Session replay (CIPA)               index.html:25
 P2  High    Ad pixels without consent           index.html:16
 M2  High    Marketing texts (TCPA)              index.html:59
 P3  Medium  Analytics cookies (EU consent)      index.html:10
 P5  Medium  Privacy policy & terms              index.html:64
 P7  Medium  "Do Not Sell or Share" (CCPA)       index.html:64
 $1  Medium  Subscriptions (CA auto-renewal)     index.html:52
 A1  Medium  Accessibility basics (ADA/WCAG)     index.html:34
 P4  Low     Google Fonts from Google (GDPR)     index.html:7
 $2  Low     Refund policy & price clarity       index.html:52
CHECK  M1 Do newsletter emails have unsubscribe + postal address? (sent outside repo)
       M3 Are "Mark"/"Sarah" and "#1 / 120,000 devs / 4 hours" real and provable?
       C3 Google, Stripe, Apple named in claims: permission and truth?
PASS   S4 Card data (Stripe Payment Link) · K1 Kids (dev tool; optional age screen)
N/A    S2 Database · S3 Admin · S5 Login · P6 Accounts · K2 App rating · C1 Uploads
       C2 Report/block · C4 AI

── S1 · High · Secret keys exposed
Found: js/app.js:2 — Airtable personal access token hard-coded in browser JS
Risk:  Anything shipped to a browser can be read by anyone; this token grants
       write (likely read) access to your Airtable base with all subscribers' data.
Fix:   Remove the token; post the form to a serverless function reading it from env.

── P1 · High · Session replay (CIPA)
Found: index.html:25 — Hotjar records every visitor on load, no consent, no policy
Risk:  California's wiretap law (§631; $5,000/violation under §637.2) is used in
       suits over session recording; per-session math is plaintiffs' theory.
Fix:   Load Hotjar only after Accept; disclose recording in the new privacy policy.

── P2 · High · Ad pixels without consent
Found: index.html:16,19 — Google Ads tag and TikTok Pixel fire on page load
Risk:  Pixels underlie many US class actions (CIPA, VPPA; courts split); in the
       EU, non-essential trackers need prior consent.
Fix:   Move pixels behind a consent banner; skip them when GPC is on.

── M2 · High · Marketing texts (TCPA)
Found: index.html:59 — phone collected "for SMS tips" with no consent checkbox
Risk:  Marketing texts need prior express written consent; $500 per text, up to
       $1,500 if willful. STOP must be honored within 10 business days.
Fix:   Add a separate unchecked SMS consent box; send phone only when ticked.
       (Assumes texts are sent from outside this repo.)

── P3 · Medium · Analytics cookies (EU consent)
Found: index.html:10 — GA4 loads and sets cookies before any choice
Risk:  In the EU, non-essential cookies need prior consent (CJEU, Planet49, 2019).
Fix:   Load gtag only after Accept, via the same banner.

── P5 · Medium · Privacy policy & terms
Found: index.html:64 — footer has no privacy/terms; site collects email and phone
Risk:  CalOPPA requires a posted privacy policy when collecting personal info from
       Californians; terms only bind users who clearly agree.
Fix:   Add draft privacy.html and terms.html from what the code does; link them.

── P7 · Medium · "Do Not Sell or Share" (CCPA)
Found: index.html:64 — ad pixels, no opt-out link, no GPC handling
Risk:  If CCPA covers you, sending data to ad platforms is "sharing": you must
       offer an opt-out and honor Global Privacy Control.
Fix:   Add "Your Privacy Choices" footer link and GPC check.

── $1 · Medium · Subscriptions (CA auto-renewal)
Found: index.html:52 — "$9/mo" Subscribe link, no renewal terms or cancel path
Risk:  California requires clear renewal terms by the button, affirmative consent,
       and easy online cancellation (B&P §17602, as amended by AB 2863).
Fix:   Add terms + unchecked consent box gating the link; add a cancel link slot.

── A1 · Medium · Accessibility basics (ADA/WCAG)
Found: index.html:34 — imgs without alt, unlabeled inputs, div "Join" button,
       outline:none, light grey reviews (#c7c7c7) and footer (#bbb) text
Risk:  ~3,100 federal ADA website suits in 2025; WCAG 2.1 AA is the usual
       yardstick. Contrast here is only spot-checked.
Fix:   Alt text, labels, real <button>, focus-visible outline, darker text.

── P4 · Low · Google Fonts from Google (GDPR)
Found: index.html:7 — DM Sans loaded from fonts.googleapis.com
Risk:  A Munich court (LG München I, 20 Jan 2022) awarded €100 for sending a
       visitor's IP to Google this way; matters with EU visitors.
Fix:   Replace with self-hosted @font-face (you download the woff2 files).

── $2 · Low · Refund policy & price clarity
Found: index.html:52 — paid subscription, no refund/cancellation policy anywhere
Risk:  Stripe's checklist expects clear refund and cancellation policies.
Fix:   Add a refund section (TODO placeholders) in terms, linked near checkout.

I can fix in code: S1 P1 P2 M2 P3 P5 P7 $1 A1 P4 $2. Needs a human: rotate Airtable
token, deploy serverless function, verify testimonials and claims, enable Stripe
customer portal, newsletter footer address, lawyer review of pages.
Not legal advice — an automated check of common traps, not a full legal review.

Apply the code fixes? (yes / no / only some IDs, e.g. "S1 S2 A1")
```

## Turn 2

Duration 155 s · cost $1.26 at API list prices · 18 tool calls

Now writing the changes.

Trackers now appear only inside the consent loader. Running syntax checks.

```
Applied
 ✓ S1  Airtable token removed from js/app.js; form posts to new
       netlify/functions/subscribe.js (reads AIRTABLE_TOKEN / AIRTABLE_BASE_ID from env,
       validates and size-limits input); .env.example and .gitignore added
 ✓ P1  Hotjar moved into js/consent.js; it loads only after "Accept". Recording is
       disclosed in privacy.html
 ✓ P2  Google Ads config and TikTok Pixel load only after "Accept", and are skipped when
       the browser sends GPC or the visitor has opted out
 ✓ P3  GA4 loads only after "Accept". The banner has Accept and Decline side by side,
       and "Cookie settings" in the footer reopens it
 ✓ P7  "Your Privacy Choices" footer link goes to privacy.html#choices, whose opt-out
       button stops ad pixels in that browser. GPC is honored
 ✓ M2  Separate unchecked SMS consent box under the phone field. The phone number is sent
       and stored only when the box is ticked, together with SmsConsentAt and
       SmsConsentText
 ✓ P5  Draft privacy.html and terms.html, built from what the code does. Linked in the
       footer and next to Join and Subscribe ("By … you agree")
 ✓ $1  Renewal terms and an unchecked consent box next to Subscribe. The link stays
       disabled until the box is ticked. On a live host it also stays disabled until
       the Stripe portal URL is set in the "Manage or cancel" link
 ✓ $2  Refund and cancellation section in terms.html#refunds, linked in the footer.
       The actual rules are left as TODO(legal-check) placeholders
 ✓ A1  Alt text on images, visible labels on inputs, and Join is now a real <button>.
       Focus outline is back (:focus-visible). Review and footer text are darker, and
       the button color now has 4.5:1 contrast. Contrast was only spot-checked
 ✓ P4  Google Fonts link removed; styles.css now uses @font-face pointing at fonts/
Checks: node --check js/app.js → ok, js/consent.js → ok,
        netlify/functions/subscribe.js → ok (first run failed on a typo in the file name
        I passed; the rerun on the right file passed). No test suite exists.
        grep: token, Google Fonts, outline:none and onclick are gone. Tracker URLs
        appear only in js/consent.js

Human TODO (code can't do these)
 [ ] Rotate the Airtable token now (it shipped to browsers, so it is compromised). If
     this repo was ever pushed, clean the token from git history
 [ ] Set AIRTABLE_TOKEN and AIRTABLE_BASE_ID (the base ID was in the old code) in your
     host. The fix assumes Netlify (Bolt's default host); if you deploy elsewhere, move
     the function to that host's serverless functions
 [ ] The /subscribe endpoint is public by design (newsletter, no login). Consider bot
     protection
 [ ] Add SmsConsentAt and SmsConsentText fields to the Airtable Subscribers table
 [ ] SMS provider: register for A2P 10DLC, handle STOP/HELP, text only numbers with
     stored consent, and keep the consent records
 [ ] Turn on the Stripe Customer Portal, paste its link into data-portal-url
     (index.html), and fill in when a cancellation takes effect
 [ ] Download dm-sans-400.woff2 and dm-sans-700.woff2 into fonts/ (until then, system
     fonts are used)
 [ ] Fill every TODO(legal-check) in privacy.html and terms.html: entity name, contact
     email, dates, retention, refund rule, governing law, email/SMS provider
 [ ] Newsletter emails: working unsubscribe link and a real postal address (CAN-SPAM)
 [ ] Check masking settings in the Hotjar dashboard and describe them in the policy
 [ ] Confirm the testimonials ("Mark", "Sarah") are real, and that "#1", "120,000
     developers at Google, Stripe and Apple" and "4 hours a day" can be proven
 [ ] Run Lighthouse or axe and do a keyboard-only pass
 [ ] Write a one-page breach plan: who decides, who you notify, and by when (every US
     state has a breach-notification law; GDPR: the regulator within 72 hours where
     feasible)
 [ ] Have a lawyer review the privacy policy, terms, refund and renewal text

Not legal advice. This checked common traps with automated pattern matching and may
miss things. Have a lawyer review your policies and flows before you rely on them.
```
