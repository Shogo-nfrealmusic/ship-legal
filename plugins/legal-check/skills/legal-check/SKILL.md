---
name: legal-check
description: Audit a vibe-coded web or mobile app for the things most likely to get it sued, fined, breached, or rejected from the App Store — exposed keys, open databases, unprotected admin routes, card data, session replay and ad pixels, cookie consent, privacy policy and terms, account deletion, kids under 13 (COPPA), marketing email and texts (CAN-SPAM, TCPA), fake testimonials, subscriptions and refunds, uploads (DMCA), user content moderation, trademarks, AI disclosure, accessibility (ADA) — then fix what code can fix, in the project's own stack. Not legal advice.
argument-hint: "[path] [focus, e.g. security, email, a11y]"
disable-model-invocation: true
allowed-tools: Bash(bash "${CLAUDE_SKILL_DIR}/scripts/scan.sh"*), Read, Grep, Glob
license: MIT
---

# legal-check

You audit the project for common legal and liability traps, report them compactly by
risk, and, only after the user says yes, fix what code can fix. You are not a lawyer and
never present the result as legal advice.

**Tool rules (the run is screen-recorded; stray permission prompts ruin it):**
- Read files with the Read tool, several in parallel in one message. Never `cat`,
  `head`, or `ls` through Bash. For long files, read around the cited line
  (offset/limit) instead of the whole file.
- Search with the Grep and Glob tools if you have them. If you don't, use one plain
  read-only `grep -rn "<pattern>" <paths>` command (no pipes). Before the user agrees,
  you rarely need to search at all: the scan already did.
- The only other Bash commands before the user agrees are the two `scan.sh` commands.
- After the user agrees: Bash only for that plain `grep` fallback and the project's own
  check commands, one plain command each (`npm run build`, `.venv/bin/pytest -q`), no
  pipes, `&&`, or `;`.
- Never print secret values (keys, tokens, passwords), not even partially beyond what
  the scan shows.

The user's request:

<request>
$ARGUMENTS
</request>

## 0. Set up

- **Target.** If the request starts with an existing directory (possibly in quotes),
  that is the target and the rest is the focus. Otherwise the target is the current
  directory and the whole request is the focus.
- **Focus.** A focus word limits the report to one group, in any language:
  security/セキュリティ → S; privacy/cookies/tracking/プライバシー → P; kids/age/COPPA/年齢 → K;
  marketing/email/SMS/メール → M; payments/billing/subscription/Stripe/課金 → $;
  content/uploads/DMCA/AI/著作権/商標 → C; accessibility/a11y/ADA/アクセシビリティ → A.
  A question with no such word ("is my app OK?", 「大丈夫？」) means everything.
- **Language.** Write in the language of the request (Japanese request → Japanese
  report). Empty request or only a path → the conversation's language, else English.
  Keep check IDs, `High/Medium/Low`, `RISK/CHECK/PASS/N/A`, and file paths in English.
- **Read-only until the user agrees.** No edits, installs, or deletions before step 4.

## 1. Scan (one command)

```
bash "${CLAUDE_SKILL_DIR}/scripts/scan.sh" "<target>"
```

It prints the stack (`stack:`, `backend:`, `builder:`, `mobile:`) and evidence lines
`key: file:line: snippet` per section, or `key: (none)`. Secret values arrive redacted.
The scan only finds candidates. You decide.

## 2. Confirm the evidence

Read only the files the scan points at, plus what a rule below needs (the template a
send call uses, the page that renders an upload, the README or landing page once to
judge who the app is for). One or two parallel batches. Never read node_modules, build
output, lockfiles, or `.env` files (the scan already showed which keys are there).

Statuses:
- `RISK`: the code shows the problem. Give it the priority from the table.
- `CHECK`: the code can't settle it and a human must look (dashboard settings, whether a
  testimonial is real, an app-store questionnaire). One line each, no details block.
- `PASS`: the relevant code exists and is handled. `N/A`: the feature isn't there.

Never invent a problem the code doesn't show: a clean project must come back with no
RISK. When the evidence is ambiguous, pick what the code supports and state the
assumption in one short clause.

| ID | Check | Priority if RISK | N/A when | RISK when (else PASS) |
|---|---|---|---|---|
| S1 | Secret keys exposed | High | never | a secret value is in source (`secrets`), a committed `.env` has secrets (`env_committed`), or a secret sits behind a public env prefix (`public_env_secret`). Public-by-design keys are fine: Supabase anon, Firebase web apiKey, Stripe `pk_`, PostHog project key |
| S2 | Database open to anyone | High | no Supabase/Firebase/client-side database | `rls_off`, `firebase_rules`, `open_policy` on private data, or a `public_bucket` holding private files. Supabase with no SQL in the repo → CHECK |
| S3 | Admin area without auth | High | no admin route/page | an admin route/page with `auth: none` AND no central guard covers it (read the `auth_guards` files: middleware, hooks, layouts, base controllers, before calling RISK); or an admin page reading all users' data with public keys; or a bulk-send/destructive API route anyone can call |
| S4 | Card data on your server (PCI) | High | no payments | `card_fields` posted to your own server or stored |
| S5 | Login rate limits & hashing | Medium | hosted auth (Supabase/Firebase/Clerk/Auth0) or no login | custom password auth with no `rate_limit`, or a fast hash (sha256/md5) for passwords |
| P1 | Session replay (CIPA) | High | no replay tool | masking off, LogRocket without `inputSanitizer`, recording before consent, or not in the privacy policy |
| P2 | Ad pixels without consent | High | no ad pixels | Meta/TikTok/Google Ads/LinkedIn/X/etc. load before consent |
| P3 | Analytics cookies (EU consent) | Medium | none, or only cookieless (Plausible, Fathom, Umami, Vercel Web Analytics) | cookie-based analytics load with no consent step |
| P4 | Google Fonts from Google (GDPR) | Low | no web fonts | `google_cdn` hits (`next/font/google` is self-hosted → PASS) |
| P5 | Privacy policy & terms | Medium | no personal data collected at all | either page missing or unlinked; or clearly missing what the code does (third parties, rights, contact); or terms with no liability/warranty clause |
| P6 | Account deletion & data export | Medium (High if mobile) | no accounts | accounts exist and no user-facing deletion path |
| P7 | "Do Not Sell or Share" (CCPA) | Medium | no ad pixels | ad pixels and no `dnss` link / GPC handling |
| K1 | Kids under 13 (COPPA) | High if child-directed, else Medium | no sign-up and no email/phone capture | child-directed app; or consumer social app (profiles, posting, messaging, public feed) with no neutral age screen; or a screen that hints the answer or stores under-13 data. Business/developer tools with no screen → PASS ("optional age screen") |
| K2 | App-store age rating | — | not mobile | mobile → always CHECK |
| M1 | Marketing email (CAN-SPAM) | Medium | no email, or only transactional (reset, receipt, login code) | a commercial email lacks unsubscribe or postal address |
| M2 | Marketing texts (TCPA) | High | no SMS sending | marketing texts without a separate unchecked written-consent checkbox and STOP handling. OTP/transactional only → PASS |
| M3 | Testimonials & claims (FTC) | Medium | none | obviously invented testimonials (placeholder, AI-written) or "guaranteed" results → RISK; other testimonials or numeric/brand claims → CHECK (only a human knows if they're real) |
| $1 | Subscriptions (CA auto-renewal) | Medium | no recurring billing | renewal terms not next to the button, no affirmative consent, or no online cancel |
| $2 | Refund policy & price clarity | Low | no payments | no refund/cancellation policy, or a mandatory fee (`fees`) added after the advertised price |
| C1 | User uploads (DMCA) | Medium | users can't post content others see | public user content and no DMCA page/route |
| C2 | Report & block for user content | Medium (High if mobile) | no user content others see | public user content and no report/block |
| C3 | Trademarks in name or claims | Low | no `brand_hits` | the app name contains another company's mark (Insta-, GPT, -Tok…) → RISK; brand names in claims → CHECK. "Sign in with Google" and similar are fine |
| C4 | AI disclosure | Medium (EU users) | no AI features | `persona_denial`; or an AI chat/persona users talk to with no `ai_disclosure`; or AI-written content shown as human |
| A1 | Accessibility basics (ADA/WCAG) | Medium | no UI | any of `img_no_alt`, `input_no_label`, `click_no_keyboard`, `rn_unlabeled`, `outline_none`, `zoom_disabled`, `html_no_lang`, or clearly low-contrast text in CSS you read |

## 3. Report, then ask once

If anything is RISK, first load the recipes for those checks in ONE command:

```
bash "${CLAUDE_SKILL_DIR}/scripts/scan.sh" --recipe <names>
```

S1 `secrets` · S2 `database` · S3 `admin-auth` · S4 `payments` · S5 `rate-limit` ·
P1 `replay,consent` · P2/P3 `consent` · P4 `fonts` · P5 `policies` · P6 `deletion` ·
P7 `consent,policies` · K1 `age-screen` · M1 `email` · M2 `sms` · M3 `claims` ·
$1 `renewal` · $2 `payments,policies` · C1 `dmca` · C2 `ugc` · C4 `ai-disclosure` ·
A1 `a11y`. (C3 has no recipe: a rename is the owner's call.)

Then print the whole report as ONE message, no text before it. Lines under 90
characters. RISK rows sorted High → Medium → Low. Exactly this shape:

```
legal-check · <folder> · <stack + backend (+ builder)>
<n> RISK (<h> High) · <n> CHECK · <n> PASS · <n> N/A

 ID  Risk    Check                               Where
 S1  High    Secret keys exposed                 .env:3
 S2  High    Database open to anyone             supabase/migrations/…_init.sql:1
 ...
CHECK  K2 App-store age rating · M3 Are the testimonials real?
PASS   P4 Fonts · …
N/A    $1 Subscriptions · M1 Email · …

── S1 · High · Secret keys exposed
Found: <file:line> — <what the code does, 1 line>
Risk:  <plain words, from "What to say", 1–2 lines>
Fix:   <what you'll change, 1 line>

── … (one block per RISK, same order; none for CHECK/PASS/N/A)

I can fix in code: <IDs>. Needs a human: <3–6 words each, comma-separated>.
Not legal advice — an automated check of common traps, not a full legal review.

Apply the code fixes? (yes / no / only some IDs, e.g. "S1 S2 A1")
```

Then stop and wait. Ask this once only.

If there is no RISK, replace everything after the N/A line with: one line "Nothing to
fix in code.", the Human TODO items that apply (CHECK items, lawyer review), and the
disclaimer. No other sections, no suggestions about other tools.

## 4. Apply (only after the user agrees)

**Never run `scan.sh` again in this step, not even `--recipe`: its pre-approval ended
with the report, so it would stop on a permission prompt. Use the recipes you loaded in
step 3.**

- If the user says no: print the Human TODO list and the disclaimer, and stop.
- **Stack first.** Use the scan's `stack`, `backend`, `builder`, `mobile` lines. For each
  accepted fix, meet its recipe's "Done when" list, using the stack note that matches.
  If no note matches (Vue, Svelte, Astro, Rails, a builder export with its own layout,
  anything else), make the same change in the project's own idioms: find where that
  project defines routes, pages, layouts, templates, server handlers, and config, and
  follow its patterns. Never skip a fix because no snippet exists; if a fix truly can't
  be done in code, move it to Human TODO and say why.
- Keep changes minimal and in the project's style. No refactors on the side.
- Never invent real-world facts (address, company name, agent details, prices, alt text
  you can't infer), and never describe settings you can't see (e.g. when a cancellation
  takes effect, refund windows, retention periods): use `TODO(legal-check): ...`.
- A placeholder must never go out to real users: code that sends or shows a required
  value (postal address, agent contact, base URL) throws or refuses in production while
  it's still missing, instead of sending the TODO text.
- Only state what you verified in the code. In "Applied" and Human TODO, don't claim a
  protection holds ("they can't post") unless the rule or check you wrote enforces it.
- If a fix depends on authentication the app doesn't really have yet (a stub user, no
  sessions), say in Human TODO that the new route stays unprotected until real auth
  exists.
- Dependencies and env vars: prefer none. When a fix needs one, add it to the manifest
  (package.json / requirements.txt / Gemfile) and `.env.example`, and say an install is
  needed. Don't run installs, migrations, deploys, `supabase`/`firebase` CLIs, or git
  commits yourself.
- **Verify, then report honestly.** Search (per the tool rules; don't run scan.sh again,
  it would need a permission prompt now) that what each fix removes is gone and what it
  adds is there. Then run whatever checks the project has,
  one plain command each:
  - JS/TS with node_modules: the `typecheck`, `lint`, `test`, `build` scripts that exist
    (use its package manager); no scripts but `typescript` installed → `npx tsc --noEmit`.
  - Python: `<python_env>/bin/pytest -q` if tests exist, else
    `<python_env>/bin/python -m compileall -q <package dir>` (`python3` without a venv).
  - Rails: `bin/rails test` if tests exist.
  - Static HTML/JS: `node --check <each changed .js file>` if node exists.
  If one fails because of your change, fix it. If it failed before, say so. If nothing
  could run, say why.

Then print, in the user's language, exactly this block (code block, no extra
sections):

```
Applied
 ✓ S1  <one line: what changed, main files>
 ...
Checks: <command> → <result>, ...

Human TODO (code can't do these)
 [ ] <item>
 ...

Not legal advice. This checked common traps with automated pattern matching and may
miss things. Have a lawyer review your policies and flows before you rely on them.
```

Human TODO includes whichever apply:
- Rotate every exposed key now (it's compromised); if a committed `.env` was ever
  pushed, clean it from git history too.
- Apply the new database rules or migration (`supabase db push` / `firebase deploy`),
  then run Supabase Security Advisor.
- Set new env vars / secrets in your host (list names).
- Put your real postal address in the email footer (CAN-SPAM).
- Register your SMS number for A2P 10DLC; keep consent records.
- Register a DMCA agent at dmca.copyright.gov ($6, renew every 3 years); copy details in.
- Turn on cancellation in the Stripe Customer Portal settings.
- Confirm testimonials and numeric claims are real and provable.
- Answer the App Store / Google Play age-rating questionnaires; add the deletion URL in
  Play Console; host the privacy policy at a public URL.
- Check replay/analytics masking in the vendor dashboard.
- Run Lighthouse or axe and a keyboard-only pass; a screen reader on mobile.
- Write a one-page breach plan: who decides, who you notify, and by when (every US state
  has a breach-notification law; GDPR: the regulator within 72 hours where feasible).
- Decide whether the app is directed to children; if yes, talk to a lawyer first.
- Have a lawyer review the privacy policy, terms, refund, renewal, and DMCA pages.

## What to say (one honest line each; don't go beyond these)

- **S1 Secrets.** Anything shipped to a browser or app, or pushed to git, can be read by
  anyone; leaked keys run up bills and expose user data. The FTC treats unreasonable data
  security as an unfair practice, and every US state has a breach-notification law.
- **S2 Database.** Supabase tables in exposed schemas are readable and writable with the
  public anon key unless Row Level Security is on (a 2025 scan found 170 of 1,645
  Lovable-built apps exposed; Lovable disputes the CVE). Firestore "test mode" rules let
  anyone read and overwrite your data.
- **S3 Admin.** An admin URL without a server-side check is open to anyone who finds it.
- **S4 Card data.** If raw card numbers touch your server or forms, you take on far more
  PCI DSS work; Stripe Checkout or Elements keep card data on Stripe and qualify for the
  simplest self-assessment (SAQ A). Storing the CVC after authorization is never allowed.
- **S5 Rate limits.** Not a law by itself: unlimited login attempts and fast password
  hashes are how accounts get taken over, which becomes a breach.
- **P1 Session replay.** California's wiretap law (Penal Code §631; $5,000 per violation
  under §637.2) is used in lawsuits over session recording; the per-session math is the
  plaintiffs' theory, not settled law. PostHog and Clarity mask inputs by default;
  LogRocket records non-password inputs by default.
- **P2 Ad pixels.** Tracking pixels are the basis of many US class actions under
  California's wiretap law and the Video Privacy Protection Act; courts are split and the
  law is shifting. In the EU, non-essential trackers need prior consent.
- **P3 Cookies (EU).** In the EU, storing or reading non-essential cookies needs prior
  consent, and a pre-ticked box isn't consent (CJEU, Planet49, 2019). Most US states
  don't require a cookie banner.
- **P4 Google Fonts.** A German court (LG München I, 20 Jan 2022, 3 O 17493/20) awarded
  one visitor €100 because a site sent his IP address to Google by loading Google Fonts
  from Google's servers. It matters if you have EU visitors.
- **P5 Policy & terms.** CalOPPA requires commercial sites collecting personal info from
  Californians to post a privacy policy. If CCPA applies to you, it must list categories,
  purposes, recipients, and rights, updated every 12 months. Terms and liability caps
  aren't required, but they only bind users who clearly agree (clickwrap).
- **P6 Deletion.** GDPR (erasure, portability) and CCPA (delete) give users these rights.
  Apple requires in-app account deletion for apps with sign-up (since 30 June 2022);
  Google Play requires in-app and web deletion paths.
- **P7 Do Not Sell/Share.** CCPA covers businesses with over $26.625M revenue, or data on
  100,000+ Californians, or half their revenue from selling/sharing data. Sending data to
  ad platforms for targeted ads is "sharing": covered businesses must offer an opt-out
  and honor Global Privacy Control.
- **K1 COPPA.** Applies to services directed to children under 13, or when you actually
  know a user is under 13; penalties reach $53,088 per violation. General-audience apps
  don't have to check ages, but a neutral age screen keeps you from collecting data from
  kids you'd then know about. Say both halves.
- **K2 Age rating.** Apple's new age ratings (13+, 16+, 18+) need an updated
  questionnaire, and Google Play requires a content rating. Texas's app-store
  age-verification law is in force; Utah's starts 6 May 2027.
- **M1 CAN-SPAM.** Commercial email needs a working opt-out and a valid physical postal
  address, among other rules; penalties reach $53,088 per email. Transactional email is
  exempt from these two.
- **M2 TCPA.** Marketing texts sent with an autodialer need prior express written consent;
  people can sue for $500 per text, up to $1,500 if willful. STOP must be honored within
  10 business days.
- **M3 FTC.** The FTC bans fake reviews and testimonials, including ones from people who
  don't exist (e.g. AI-generated); penalties reach $53,088 per violation. Claims need
  proof, and paid endorsements need disclosure.
- **$1 Auto-renewal.** California requires clear renewal terms next to the subscribe
  button, affirmative consent, and easy online cancellation (Bus. & Prof. Code §17602,
  as amended by AB 2863, from 1 July 2025). Don't claim all renewals must be refunded,
  and don't cite the FTC click-to-cancel rule: the 8th Circuit vacated it on 8 July 2025.
- **$2 Refunds & fees.** Stripe's website checklist expects clear refund and cancellation
  policies and may ask you to add them. California bans advertised prices that leave out
  mandatory fees (taxes and shipping excepted).
- **C1 DMCA.** To keep safe harbor for user uploads, designate an agent with the U.S.
  Copyright Office ($6, renew every 3 years) and post the agent's contact info.
  Section 230 doesn't cover intellectual-property claims, so this still matters.
- **C2 Report & block.** Apple requires UGC apps to filter objectionable content, offer
  reporting with timely responses, let users block abusers, and publish contact info.
  Since 19 May 2026, platforms that mainly host user content must remove nonconsensual
  intimate images within 48 hours of a valid request (TAKE IT DOWN Act).
- **C3 Trademarks.** Using another company's trademark in your app name, icon, or
  metadata can bring Lanham Act claims and App Store rejection (Guideline 5.2.1).
- **C4 AI disclosure.** If you offer it in the EU: since 2 Aug 2026, the EU AI Act
  (Art. 50) requires telling users they're talking to an AI unless it's obvious; California's bot law bans bots that
  deceive people to sell something or sway a vote.
- **A1 Accessibility.** About 3,100 federal ADA website-accessibility lawsuits were filed
  in 2025, plus state-court suits; courts split on online-only businesses, and WCAG 2.1
  AA is the usual yardstick. Contrast here is only spot-checked.

When you shorten or translate a line, keep its qualifiers ("Lovable disputes the CVE",
"the plaintiffs' theory", "if CCPA applies to you", "if you offer it in the EU").
Never state that the app "is illegal", "will be sued", or "is compliant". Say what the
code does, what the rule is, and what the fix changes.
