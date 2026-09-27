# Expo (React Native) + Firebase

Prompt: `/legal-check` → `yes`

## Turn 1

Duration 43 s · cost $0.62 at API list prices · 10 tool calls

```
legal-check · expo · expo + firebase
11 RISK (5 High) · 2 CHECK · 0 PASS · 11 N/A

 ID  Risk    Check                               Where
 S1  High    Secret keys exposed                 .env:2
 S2  High    Database open to anyone             storage.rules:5
 M2  High    Marketing texts (TCPA)              functions/index.js:12
 P6  High    Account deletion & data export      app/index.tsx:14
 C2  High    Report & block for user content     app/feed.tsx:34
 P5  Medium  Privacy policy & terms              app/index.tsx:26
 K1  Medium  Kids under 13 (COPPA)               app/index.tsx:14
 C1  Medium  User uploads (DMCA)                 app/feed.tsx:24
 C4  Medium  AI disclosure                       app/feed.tsx:25
 A1  Medium  Accessibility basics                app/index.tsx:22
 C3  Low     Trademarks in name or claims        app.json:3
CHECK  K2 App-store age rating · M3 Is the "50% off" offer real?
PASS   (none)
N/A    S3 Admin · S4 Card data · S5 Login (Firebase Auth) · P1 Replay · P2 Pixels ·
       P3 Analytics · P4 Fonts · P7 Do Not Sell · M1 Email · $1 Subs · $2 Refunds

── S1 · High · Secret keys exposed
Found: .env:2, lib/caption.ts:5 — EXPO_PUBLIC_OPENAI_API_KEY is bundled into the app,
       and .env is committed to git
Risk:  Anything shipped in an app or pushed to git can be read by anyone; leaked keys
       run up bills. The FTC treats unreasonable data security as an unfair practice.
Fix:   Move the OpenAI call into a signed-in-only Cloud Function, un-prefix the key,
       gitignore .env

── S2 · High · Database open to anyone
Found: firestore.rules:5, storage.rules:5 — Firestore test mode (anyone can read/write
       every doc, incl. users' emails and phones); Storage `if true`
Risk:  Firestore "test mode" rules let anyone read and overwrite your data.
Fix:   Per-user rules: users/{uid} owner-only, posts public-read / owner-write,
       Storage writes by signed-in users only, images under a size limit

── M2 · High · Marketing texts (TCPA)
Found: functions/index.js:12 — daily promo text ("InstaVibe Plus 50% off") to every user;
       app/index.tsx:15 sets dailyTexts: true at sign-up; consent is 10px grey fine print
Risk:  Marketing texts with an autodialer need prior express written consent; people can
       sue for $500 per text, up to $1,500 if willful. STOP must be honored.
Fix:   Separate unchecked SMS consent switch storing time + wording; send only to
       consented, non-opted-out numbers; add a STOP webhook

── P6 · High · Account deletion & data export
Found: app/index.tsx:14 — accounts are created; no way to delete them or export data
Risk:  GDPR and CCPA give users deletion rights. Apple requires in-app account deletion
       for apps with sign-up; Google Play requires in-app and web deletion paths.
Fix:   Settings screen with "Delete my account" (callable Function removes user, doc,
       posts, files) and "Download my data"

── C2 · High · Report & block for user content
Found: app/feed.tsx:34 — everyone's posts shown in a public feed, no report or block
Risk:  Apple requires UGC apps to offer reporting, blocking, and published contact info.
       TAKE IT DOWN Act: remove nonconsensual intimate images within 48 hours.
Fix:   Report and Block actions per post, write-only `reports` collection, feed hides
       blocked users, contact placeholder

── P5 · Medium · Privacy policy & terms
Found: app/index.tsx:26 — collects email, phone, photos; no privacy policy or terms
Risk:  CalOPPA requires commercial apps collecting personal info from Californians to
       post a privacy policy. Terms only bind users who clearly agree.
Fix:   Draft privacy and terms screens from what the code does; link them at sign-up

── K1 · Medium · Kids under 13 (COPPA)
Found: app/index.tsx:14 — consumer photo-sharing app with a public feed, no age screen
Risk:  COPPA applies to child-directed apps or when you know a user is under 13. General
       apps needn't check ages, but a neutral screen avoids collecting kids' data.
Fix:   Neutral birth month/year step before sign-up; under-13 gets nothing stored; rules
       require is13Plus on the user doc

── C1 · Medium · User uploads (DMCA)
Found: app/feed.tsx:24 — users upload photos everyone sees; no DMCA page
Risk:  To keep safe harbor for user uploads, designate an agent with the U.S. Copyright
       Office and post the agent's contact info.
Fix:   DMCA screen with notice/counter-notice steps and agent placeholders

── C4 · Medium · AI disclosure
Found: app/feed.tsx:25 — every caption is written by GPT and shown as the user's own
Risk:  In the EU, the AI Act (Art. 50) requires disclosing AI; AI-written content
       shouldn't pass as human.
Fix:   Store aiCaption: true and label those captions "AI-generated caption"

── A1 · Medium · Accessibility basics
Found: app/index.tsx:22-26, app/feed.tsx:41 — unlabeled inputs and buttons; "＋" is
       icon-only; #bbb 10px text on white is low contrast
Risk:  About 3,100 federal ADA website suits in 2025; WCAG 2.1 AA is the usual yardstick.
       Contrast was only spot-checked.
Fix:   accessibilityLabel/Role on inputs, buttons, images; darker, larger fine print

── C3 · Low · Trademarks in name or claims
Found: app.json:3 — the name "InstaVibe" uses "Insta-", associated with Instagram
Risk:  Using another company's mark in your app name can bring Lanham Act claims and
       App Store rejection (Guideline 5.2.1).
Fix:   No code fix; renaming is your call

I can fix in code: S1 S2 M2 P6 C2 P5 K1 C1 C4 A1. Needs a human: rotate OpenAI key,
deploy Firebase rules, A2P 10DLC registration, DMCA agent registration, rename decision,
store age-rating questionnaires, lawyer policy review.
Not legal advice — an automated check of common traps, not a full legal review.

Apply the code fixes? (yes / no / only some IDs, e.g. "S1 S2 A1")
```

## Turn 2

Duration 210 s · cost $1.47 at API list prices · 23 tool calls

Applying the fixes. I'll start with the Cloud Functions (server side for S1, K1, M2, P6).

Now the client: Firebase setup, caption call, legal constants.

Sign-up screen (age screen, SMS consent, clickwrap, labels):

Now settings (deletion/export) and the policy screens:

Gitignore and env example:

Verifying: removed patterns gone, then checks.

```
Applied
 ✓ S1  OpenAI call moved to a signed-in-only Cloud Function using a Functions secret
       (functions/index.js, lib/caption.ts); .env added to .gitignore; .env.example
 ✓ S2  Firestore rules: users owner-read only; posts public read, owner write, 13+
       required; reports write-only. Storage: owner-only writes, images under 10 MB
 ✓ M2  Unchecked SMS consent switch; consent stored with time and wording; texts go
       only to consenting numbers that haven't opted out; smsInbound STOP webhook
       (Twilio-signed); "Reply STOP" added to message (app/index.tsx, functions)
 ✓ P6  Settings screen: Delete my account (removes auth user, profile, posts, photos,
       reports) and Download my data (JSON via Share) (app/settings.tsx, functions)
 ✓ C2  Report and Block on others' posts; blocked users hidden; contact shown in
       Settings; terms cover the 48-hour NCII removal (app/feed.tsx, firestore.rules)
 ✓ P5  Draft privacy and terms screens built from the code; sign-up clickwrap links;
       links in Settings (app/privacy.tsx, app/terms.tsx)
 ✓ K1  Neutral birth month/year at sign-up, checked in the signUp Cloud Function;
       under 13: nothing stored, neutral message, 24 h in-memory retry block; only
       is13Plus stored; posting rule requires it
 ✓ C1  DMCA screen: notice, counter-notice, repeat-infringer policy, agent TODOs
       (app/dmca.tsx), linked from terms and settings
 ✓ C4  Posts store aiCaption: true; feed shows an "AI-generated caption" label
 ✓ A1  accessibilityLabel/Role on inputs, buttons, images; low-contrast fine print
       replaced with #444, 13px (contrast only spot-checked)
 – C3  Not changed: renaming "InstaVibe" is your call
Checks: npm run typecheck → pass, node --check functions/index.js → pass,
        grep → removed patterns gone (remaining "if true" = intended public read)

Human TODO (code can't do these)
 [ ] Rotate the OpenAI key now (it shipped in the app and is in git); delete the
     EXPO_PUBLIC_OPENAI_API_KEY line from .env; run `git rm --cached .env` and
     clean .env from git history if it was ever pushed
 [ ] firebase functions:secrets:set OPENAI_API_KEY; set TWILIO_SID, TWILIO_TOKEN,
     TWILIO_WEBHOOK_URL for Functions; point Twilio's inbound webhook at smsInbound
 [ ] Install functions deps, then review and run
     firebase deploy --only functions,firestore:rules,storage
 [ ] Disable client-side sign-up in Firebase Auth settings (Identity Platform
     "user actions"), so the age check in signUp can't be skipped. Accounts made
     without it have no is13Plus profile, and the rules block them from posting
 [ ] Existing users: none have SMS consent under the new rules, so they get no
     texts until they opt in. Their profiles have no is13Plus, so they can't post
     until you handle them (for example, ask them to re-confirm their age)
 [ ] Photos uploaded before this change (posts/<timestamp>.jpg) aren't tied to a
     user, so account deletion doesn't remove them; clean them up by hand
 [ ] Register your SMS number for A2P 10DLC; keep consent records
 [ ] Fill in every TODO(legal-check) in lib/legal.ts: company, contact email,
     effective date, retention, governing law, DMCA agent. Production builds
     throw on these screens until you do
 [ ] Register a DMCA agent at dmca.copyright.gov ($6, renew every 3 years); copy
     the details in
 [ ] Decide who reviews reports and how fast (48 h for NCII); add a filter for
     objectionable content (App Store 1.2)
 [ ] Confirm the "50% off" InstaVibe Plus offer is real
 [ ] Answer the App Store / Google Play age-rating questionnaires; add the deletion
     URL in Play Console; host the privacy policy at a public URL
 [ ] Decide whether to rename "InstaVibe" (Insta- mark, App Store 5.2.1)
 [ ] Consider letting users describe their photos (image alt text is generic)
 [ ] Test with a screen reader (VoiceOver/TalkBack) and do a keyboard-only pass
 [ ] Write a one-page breach plan: who decides, who you notify, and by when
 [ ] Have a lawyer review the privacy policy, terms, and DMCA pages

Not legal advice. This checked common traps with automated pattern matching and may
miss things. Have a lawyer review your policies and flows before you rely on them.
```
