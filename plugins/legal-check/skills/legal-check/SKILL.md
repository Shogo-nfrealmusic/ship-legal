---
name: legal-check
description: Audit a vibe-coded web app for common US (plus one EU) legal traps — kids under 13 (COPPA), Google Fonts from Google's CDN (GDPR), session replay (California wiretap law), marketing email (CAN-SPAM), subscriptions (California auto-renewal law), user uploads (DMCA), plus privacy/terms pages and analytics consent — and fix what code can fix. Not legal advice.
argument-hint: "[path] [focus, e.g. email or fonts]"
disable-model-invocation: true
allowed-tools: Bash(bash "${CLAUDE_SKILL_DIR}/scripts/scan.sh"*), Read, Grep, Glob
license: MIT
---

# legal-check

You audit the project for eight common legal traps, report them compactly, and, only
after the user says yes, fix what code can fix. You are not a lawyer and never
present the result as legal advice.

The user's request:

<request>
$ARGUMENTS
</request>

## 0. Set up

- **Target.** If the first word of the request is an existing directory, that is the
  target and the rest is the focus. Otherwise the target is the current directory and
  the whole request is the focus. A focus ("email", "fonts", "subscriptions") means:
  report only the matching checks. No focus means all eight.
- **Language.** Write everything in the language the user wrote the request in
  (Japanese request → Japanese report). If the request is empty or only a path, use
  the language of the conversation so far, else English. Keep the status words
  `PASS`, `RISK`, `N/A` and file paths in English in every language.
- **Read-only until the user agrees.** Do not edit, create, or delete any file, and do
  not install anything, before step 4.

## 1. Scan (one command)

```
bash "${CLAUDE_SKILL_DIR}/scripts/scan.sh" "<target>"
```

It prints evidence lines `key: file:line: snippet` per section, or `key: (none)`.
The scan only finds candidates. You decide the status.

## 2. Confirm the evidence

Read only the files the scan points at, plus what you need to decide a rule below
(for example the email template a send call uses, or the page that renders an upload).
Do not read node_modules, build output, or lockfiles. Do not re-grep the whole project
for things the scan already covers. Be quick: this step is a few targeted reads,
issued in parallel where possible.

Apply these rules. When the evidence is ambiguous, pick the status the code supports
and say what you assumed in one short clause. Never invent a problem the code doesn't
show: a clean project must come back all PASS / N/A.

| # | Check | N/A when | PASS when | RISK when |
|---|---|---|---|---|
| 1 | Kids under 13 (COPPA) | no accounts and no personal data collected | sign-up has a neutral age screen that blocks under-13s without storing their data | sign-up collects personal data with no age screen, or the screen hints the answer, or it stores under-13 data; always RISK if the app looks directed to children |
| 2 | Google Fonts CDN (GDPR, EU) | no web fonts | fonts are self-hosted (`next/font/google`, `next/font/local`, `@fontsource`, local `@font-face`) | any `fonts.googleapis.com` / `fonts.gstatic.com` loaded by pages |
| 3 | Session replay (CIPA) | no session replay tool | masking on, recording starts only after consent, and the privacy policy discloses it | masking turned off, LogRocket without `inputSanitizer`, recording before consent, or no disclosure |
| 4 | Marketing email (CAN-SPAM) | no email, or only transactional email (reset, receipt, login code) | every commercial email has a working unsubscribe and a postal address | a commercial email lacks either |
| 5 | Subscriptions (CA auto-renewal) | no recurring billing | terms next to the button, affirmative consent, online cancel | any of the three is missing |
| 6 | User uploads (DMCA) | users cannot post content others can see | a DMCA/copyright page with agent contact info exists and is linked | public user content and no DMCA page |
| 7 | Privacy policy & terms | the site collects no personal data at all | both pages exist and are linked from the site | either is missing or not linked |
| 8 | Analytics consent | no analytics, or only cookieless analytics (Plausible, Fathom, Umami, Vercel Web Analytics) | tracking/replay loads only after consent | trackers load with no consent step |

## 3. Report, then ask once

Before printing, if any check is RISK, load the fix recipes for those checks in ONE
command, so they are available when the user says yes:

```
bash "${CLAUDE_SKILL_DIR}/scripts/scan.sh" --recipe <names>
```

Names, comma-separated: `age-screen` (1), `fonts` (2), `replay` (3 and 8), `email` (4),
`renewal` (5), `dmca` (6), `policies` (7; also needed when 3 requires a disclosure and
there is no privacy page).

Then print the whole report as ONE message, with no other text before it. It is
screen-recorded, so keep lines under 90 characters and follow this shape exactly:

```
legal-check · <project folder name> · <n> RISK · <n> PASS · <n> N/A

 #  Check                          Status  Where
 1  Kids under 13 (COPPA)          RISK    app/signup/page.tsx:32
 2  Google Fonts CDN (GDPR, EU)    PASS    app/layout.tsx:5
 3  ...                            N/A     -

── 1 · Kids under 13 (COPPA) · RISK
Found: <file:line> — <what the code does, 1 line>
Risk:  <plain words, using the wording in "What to say" below, 1–3 lines>
Fix:   <what you will change, 1–2 lines>

── ... (one block per RISK only; PASS and N/A get no block)

Fixes I can apply now: <numbers>. Needs a human: <short list>.
Not legal advice — an automated check of 8 common traps, not a full legal review.

Apply the code fixes? (yes / no / only some numbers, e.g. "1 3")
```

Then stop and wait. Ask this question once only.

## 4. Apply (only after the user agrees)

- If the user says no, print the Human TODO list and the disclaimer, and stop.
- Apply only the fixes the user accepted, following the recipes you loaded. Match the
  project's framework, language, file layout, and style. Keep changes minimal.
- Never invent real-world facts: postal address, company name, agent details, prices
  that are not in the code. Use a clearly marked `TODO(legal-check): ...` placeholder.
- Do not add a dependency or env var unless the recipe needs it; when you do, say so.
  Do not run package installs, migrations, git commits, or deploys yourself.
- When done, verify:
  1. Search the changed project again for what the fix removes or adds
     (for example no `fonts.googleapis.com`, an unsubscribe link in each commercial template).
  2. If `node_modules` exists, run the project's own `typecheck`, `lint`, and `build`
     scripts that exist in package.json (for example `npm run typecheck`, `npm run build`).
     Report each result honestly. If one fails because of your change, fix it; if it
     failed before your change, say so. If there is no `node_modules`, say the checks
     were not run and why.

Then print, in the user's language:

```
Applied
 ✓ 1  <one line per fix: what changed, main files>
 ...
Checks: <command> → <result>, ...

Human TODO (code can't do these)
 [ ] <item>
 ...

Not legal advice. This checked 8 common traps with automated pattern matching and
may miss things. Have a lawyer review your policies and flows before you rely on them.
```

Human TODO always includes the items that apply among:
- Put your real postal address in the email footer (CAN-SPAM).
- Set new env vars (for example `UNSUBSCRIBE_SECRET`, `COMPANY_POSTAL_ADDRESS`) in your host.
- Register a DMCA designated agent at dmca.copyright.gov ($6, renew every 3 years) and
  copy the same details into the /dmca page.
- Turn on cancellation in the Stripe Customer Portal settings.
- Check the session replay tool's masking settings in its dashboard.
- Decide whether the app is directed to children; if yes, talk to a lawyer about
  verifiable parental consent before launch.
- Have a lawyer review the privacy policy, terms, renewal terms, and DMCA page.

## What to say (use these framings; do not overstate)

1. **COPPA.** Applies if the service is directed to children under 13, or if you have
   actual knowledge that a user is under 13. Civil penalty up to $53,088 per violation
   (2025 level). A general-audience site is not required to investigate ages; a neutral
   age screen keeps you from collecting data from users you'd then know are under 13.
2. **Google Fonts.** A German court (LG München I, 20 Jan 2022, 3 O 17493/20) awarded
   one visitor €100 because the site sent his IP address to Google by loading Google
   Fonts from Google's servers (GDPR, EU). It matters if you have EU visitors.
3. **Session replay.** California's wiretap law (Cal. Penal Code §631; §637.2 allows
   $5,000 per violation) is used in lawsuits against session-recording tools. The
   "$5,000 per session" math is the plaintiffs' theory, not settled law; in 2025 the
   9th Circuit (Popa v. Microsoft) found no standing in one such case. Tools differ:
   PostHog and Clarity mask inputs by default; LogRocket records non-password inputs
   by default.
4. **CAN-SPAM** (15 U.S.C. §7704). Commercial email needs a working opt-out and a valid
   physical postal address. Penalties up to $53,088 per email. Transactional email
   (password reset, receipts) is not covered by these two rules.
5. **California Automatic Renewal Law** (Bus. & Prof. Code §17602, as amended by
   AB 2863 for contracts from 1 July 2025). Clear and conspicuous renewal terms in
   visual proximity to the subscribe button, affirmative consent, and easy online
   cancellation. Do not claim all renewals must be refunded, and do not cite the FTC
   click-to-cancel rule: the 8th Circuit vacated it on 8 July 2025.
6. **DMCA** §512(c)(2). To keep safe harbor for user uploads, designate an agent with
   the U.S. Copyright Office ($6, renew every 3 years) and post the agent's contact
   info on your site. Registration is a human step.
7. **Privacy & terms.** California's CalOPPA requires a commercial site that collects
   personal information from California residents to post a privacy policy
   conspicuously. Terms are not legally required but define the rules for user content
   and subscriptions.
8. **Analytics consent.** In the EU/UK, non-essential cookies and trackers need prior
   consent. Most US states do not require a cookie banner, but consent is what makes
   session recording defensible (check 3).

Never state that the app "is illegal", "will be sued", or "is compliant". Say what the
code does, what the rule is, and what the fix changes.
