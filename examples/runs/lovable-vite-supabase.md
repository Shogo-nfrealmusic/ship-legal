# Lovable-style Vite + React + Supabase

Prompt: `/legal-check` → `yes`

## Turn 1

Duration 51 s · cost $0.68 at API list prices · 12 tool calls

```
legal-check · lovable · vite-react + supabase (lovable)
14 RISK (4 High) · 0 CHECK · 0 PASS · 10 N/A

 ID  Risk    Check                               Where
 S1  High    Secret keys exposed                 .env:3
 S2  High    Database open to anyone             supabase/migrations/…_init.sql:1
 S3  High    Admin area without auth             src/pages/Admin.tsx:8
 P2  High    Ad pixels without consent           index.html:10
 P5  Medium  Privacy policy & terms              (no /privacy, /terms)
 P6  Medium  Account deletion & data export      (none)
 P7  Medium  "Do Not Sell or Share" (CCPA)       index.html:16
 K1  Medium  Kids under 13 (COPPA)               src/pages/Signup.tsx:14
 M3  Medium  Testimonials & claims (FTC)         src/pages/Landing.tsx:14
 C1  Medium  User uploads (DMCA)                 src/pages/Feed.tsx:19
 C2  Medium  Report & block for user content     src/pages/Feed.tsx:34
 C4  Medium  AI disclosure                       src/lib/openai.ts:12
 A1  Medium  Accessibility basics                src/index.css:4
 P4  Low     Google Fonts from Google            index.html:8
CHECK  (none)
PASS   (none)
N/A    S4 Card data · S5 Hosted auth · P1 Replay · P3 Analytics · K2 Not mobile ·
       M1 Email · M2 SMS · $1 Subscriptions · $2 Payments · C3 Trademarks

── S1 · High · Secret keys exposed
Found: .env:3, src/lib/openai.ts:7 — VITE_OPENAI_API_KEY is in the browser bundle;
       .env is committed to git
Risk:  Anything shipped to a browser or pushed to git can be read by anyone; leaked
       keys run up bills. The FTC treats unreasonable data security as unfair.
Fix:   Move the OpenAI call into a Supabase Edge Function using a server-only key.

── S2 · High · Database open to anyone
Found: …_init.sql:1,8 — profiles (with emails) and posts have no Row Level Security
Risk:  With RLS off, anyone holding the public anon key can read and write these
       tables (a 2025 scan found 170 of 1,645 Lovable apps exposed).
Fix:   New migration: turn on RLS, add owner policies, move emails out of public read.

── S3 · High · Admin area without auth
Found: src/pages/Admin.tsx:8 — /admin reads every user's email with the anon key,
       no guard
Risk:  An admin URL without a server-side check is open to anyone who finds it.
Fix:   Edge Function checks the admin JWT and uses the service role; page shows
       "Not authorized".

── P2 · High · Ad pixels without consent
Found: index.html:10 — Meta Pixel loads and tracks PageView on every visit
Risk:  Pixels are the basis of many US wiretap/VPPA class actions (courts split); in
       the EU, non-essential trackers need prior consent.
Fix:   Load the pixel only after Accept on a consent banner; GPC means no pixel.

── P5 · Medium · Privacy policy & terms
Found: no privacy or terms page; sign-up collects email/username, uses Meta + OpenAI
Risk:  CalOPPA requires a posted privacy policy; terms only bind users who clearly
       agree (clickwrap).
Fix:   Draft /privacy and /terms from the code, footer links, clickwrap at sign-up.

── P6 · Medium · Account deletion & data export
Found: accounts via supabase.auth.signUp, no deletion or export path
Risk:  GDPR (erasure, portability) and CCPA (delete) give users these rights.
Fix:   "Delete my account" + "Download my data" via a delete-account Edge Function.

── P7 · Medium · "Do Not Sell or Share" (CCPA)
Found: index.html:16 — Meta Pixel, no opt-out link or GPC handling
Risk:  Sending data to ad platforms for targeted ads is "sharing" under CCPA; covered
       businesses must offer an opt-out and honor GPC.
Fix:   Footer "Your Privacy Choices" link that opts out; GPC honored.

── K1 · Medium · Kids under 13 (COPPA)
Found: Signup.tsx:14 — public social feed (usernames, posts, photos), no age screen
Risk:  COPPA applies if you actually know a user is under 13 ($53,088/violation);
       general-audience apps needn't check ages, but a neutral screen avoids that.
Fix:   Neutral birth month/year screen checked server-side; store only is_13_plus.

── M3 · Medium · Testimonials & claims (FTC)
Found: Landing.tsx:14 — "Guaranteed results in 30 days", "50,000+", unverified
       quotes
Risk:  The FTC bans fake testimonials and needs proof for claims ($53,088 per
       violation).
Fix:   Remove "Guaranteed"; mark the quotes and the 50,000+ claim with TODOs.

── C1 · Medium · User uploads (DMCA)
Found: Feed.tsx:19 — users upload photos shown publicly, no DMCA page
Risk:  DMCA safe harbor needs a registered agent and their contact info posted;
       Section 230 doesn't cover IP claims.
Fix:   Add a /dmca page (agent details as TODO) and link it from footer and terms.

── C2 · Medium · Report & block for user content
Found: Feed.tsx:34 — public posts, no report or block
Risk:  Apple requires report/block for UGC; TAKE IT DOWN Act needs 48 h removal of
       nonconsensual intimate images.
Fix:   reports + blocks tables with RLS, Report/Block buttons, feed hides blocked users.

── C4 · Medium · AI disclosure
Found: openai.ts:12 — "Never say you are an AI"; Landing.tsx:13 "AI-free trainer"
Risk:  EU AI Act Art. 50 requires telling users they're talking to an AI; California's
       bot law bans deceptive bots used to sell.
Fix:   Remove the denial from the prompt, add an "AI assistant" notice, fix the copy.

── A1 · Medium · Accessibility basics
Found: index.css:4 outline:none; index.html:5 zoom blocked; imgs without alt; inputs
       with no label; clickable div in Coach.tsx:25; .muted #555 on #0f0f10
Risk:  About 3,100 federal ADA web lawsuits were filed in 2025; WCAG 2.1 AA is the
       usual yardstick. Contrast only spot-checked.
Fix:   Add labels and alt text, use a real button, show focus, allow zoom, fix contrast.

── P4 · Low · Google Fonts from Google
Found: index.html:8 — Poppins loaded from fonts.googleapis.com
Risk:  A Munich court (LG München I, 2022) awarded €100 because Google Fonts sent a
       visitor's IP to Google; matters for EU visitors.
Fix:   Self-host Poppins via @fontsource/poppins; drop the Google links.

I can fix in code: S1 S2 S3 P2 P5 P6 P7 K1 M3 C1 C2 C4 A1 P4.
Needs a human: rotate OpenAI key, apply migration, register DMCA agent,
verify testimonials and numbers, lawyer review.
Not legal advice — an automated check of common traps, not a full legal review.

Apply the code fixes? (yes / no / only some IDs, e.g. "S1 S2 A1")
```

## Turn 2

Duration 289 s · cost $1.95 at API list prices · 41 tool calls

Applying the fixes now.

Checks look clean (the only pixel init left is the consent-gated loader). Running typecheck and build now.

I applied all 14 code fixes. Typecheck and build both pass, but nothing is live until you apply the new database migration and deploy the four new server functions (Supabase Edge Functions). Until then, sign-up, the AI coach chat, the admin page and account deletion won't work.

```
Applied
 ✓ S1  OpenAI call moved to server function supabase/functions/coach, key read server-side
       src/lib/openai.ts calls it; .env added to .gitignore; .env.example lists vars
 ✓ S2  New migration 20260928000000_legal_check_rls.sql: RLS on, own-row read on profiles
       public-read/own-insert posts, username set by DB, photo uploads only to own folder
 ✓ S3  /admin fetches via supabase/functions/admin-users, which checks ADMIN_EMAILS
       server-side; everyone else sees "Not authorized"
 ✓ P2  Meta Pixel removed from index.html; loads only after Accept (src/lib/consent.ts,
       ConsentBanner); Accept/Decline equal; GPC blocks it; "Cookie settings" in footer
 ✓ P7  /privacy-choices page with "Do Not Sell or Share" opt-out; footer link
 ✓ P5  Draft /privacy and /terms built from the code, footer links, "By signing up you agree"
       at sign-up; required details come from src/lib/legal.ts (prod build throws if empty)
 ✓ P6  /account: "Download my data" (JSON) and "Delete my account" (supabase/functions/
       delete-account removes photos + auth user; FKs now on delete cascade)
 ✓ K1  Sign-up via supabase/functions/signup: neutral birth month/year screen, under 13 →
       nothing stored + 24 h browser marker; stores only is_13_plus; posting policy requires it
 ✓ M3  "Guaranteed results in 30 days" removed; TODOs on the testimonials and "50,000+"
 ✓ C1  /dmca page (notice, counter-notice, repeat-infringer policy), linked from footer/terms
 ✓ C2  reports + blocks tables with RLS; Report/Block on every post; feed hides blocked users
       terms cover prompt review and 48 h removal of nonconsensual intimate images
 ✓ C4  "Never say you are an AI" removed from system prompt; chat notice + "Max (AI)" labels
       landing "AI-free" → "AI personal trainer"
 ✓ A1  Labels on all fields, feed image alt text, send button is a real <button>,
       :focus-visible outline, zoom allowed, .muted and button text contrast raised
 ✓ P4  Google Fonts links removed; Poppins @font-face pointing to /public/fonts
Checks: npm run typecheck → pass, npm run build → pass (font files not yet present,
        chunk-size warning); grep → no VITE_OPENAI / Google Fonts / zoom lock / AI denial left

Human TODO (code can't do these)
 [ ] Rotate the OpenAI key now (it shipped in the bundle and is in git); delete the
     VITE_OPENAI_API_KEY line from .env, `git rm --cached .env`, clean .env from git history
 [ ] Set secrets: `supabase secrets set OPENAI_API_KEY=... ADMIN_EMAILS=you@example.com`
 [ ] Deploy functions: coach, admin-users, delete-account, signup (`supabase functions deploy`)
 [ ] Review and apply the migration (`supabase db push`), then run Supabase Security Advisor
 [ ] Existing users have is_13_plus = false and can't post until you screen them
 [ ] Clients can still call supabase.auth.signUp directly and skip the screen; such accounts
     get no profile and can't post, but a user is still created. Consider restricting
     sign-ups to the function (dashboard setting)
 [ ] Fill in src/lib/legal.ts (company, contact email, effective date, governing law, DMCA
     agent). Production pages refuse to render until you do
 [ ] Register a DMCA agent at dmca.copyright.gov ($6, renew every 3 years); copy details in
 [ ] Confirm the testimonials and "50,000+ athletes" are real and provable, or remove them
 [ ] Write real alt text for the hero image (src/pages/Landing.tsx)
 [ ] Download Poppins 400/600/700 .woff2 into public/fonts/ (poppins-400.woff2, etc.)
 [ ] Decide who reviews reports and how fast; consider a keyword filter for posts
 [ ] Run Lighthouse or axe and a keyboard-only pass (contrast was only spot-checked)
 [ ] Write a one-page breach plan: who decides, who you notify, and by when
 [ ] Have a lawyer review the privacy policy, terms, and DMCA pages

Not legal advice. This checked common traps with automated pattern matching and may
miss things. Have a lawyer review your policies and flows before you rely on them.
```
