# legal-check for Claude Code

`/legal-check` audits a vibe-coded web app for eight common legal traps, then fixes what code can fix.

```
/legal-check
```

It checks for:

| # | Trap | Law |
|---|---|---|
| 1 | Sign-up with no age screen | COPPA (US) |
| 2 | Google Fonts loaded from Google's servers | GDPR (EU) |
| 3 | Session replay recording typed text, or recording before consent | California wiretap law (CIPA) |
| 4 | Marketing email with no unsubscribe link or postal address | CAN-SPAM (US) |
| 5 | Subscribe button with no renewal terms, consent, or online cancel | California Automatic Renewal Law |
| 6 | User uploads with no DMCA page | DMCA §512(c) (US) |
| 7 | No privacy policy or terms page | CalOPPA (California) |
| 8 | Analytics that load before consent | EU/UK consent rules |

**This is not legal advice.** It is an automated check of eight common traps, not a full legal review. It can miss things. Have a lawyer review your policies and flows before you rely on them.

## How it works

1. **Scan (read-only).** A bundled shell script greps your source for evidence: sign-up forms, font links, replay SDKs, email sends, Stripe subscriptions, file uploads, policy pages. It skips `node_modules`, build output, and lockfiles. It takes about a second.
2. **Judge.** Claude reads only the files the scan points at and marks each check `PASS`, `RISK`, or `N/A`, using fixed rules. For example, a password-reset email is transactional, so CAN-SPAM's unsubscribe rule is `N/A`. And `next/font/google` self-hosts fonts at build time, so it is a `PASS`.
3. **Report, then ask once.** First a summary table, then one short block per `RISK`: where it is (`file:line`), the risk in plain words, and the fix. Then one question: apply the fixes?
4. **Fix.** Only after you say yes. It edits your code, then runs your own `typecheck` / `lint` / `build` scripts if `node_modules` exists.
5. **Human TODO.** It lists what code can't do: your real postal address, registering a DMCA agent, turning on cancellation in Stripe, and a lawyer's review.

It answers in the language you ask in. For example, `/legal-check このアプリ大丈夫？` gets a Japanese report.

## Install

### Option A: as a plugin (recommended)

In Claude Code:

```
/plugin marketplace add Shogo-nfrealmusic/ship-legal
/plugin install legal-check@ship-legal
```

Then run `/legal-check`. Plugin skills are also available under the namespaced name `/legal-check:legal-check`.

### Option B: copy the skill folder

```bash
git clone https://github.com/Shogo-nfrealmusic/ship-legal.git
cp -R ship-legal/plugins/legal-check/skills/legal-check ~/.claude/skills/
```

To use it in one project only, copy the folder into that project's `.claude/skills/` instead. The scanner skips `.claude/`, so its own recipe files are never reported as findings.

### Try it without installing

```bash
claude --plugin-dir ./ship-legal/plugins/legal-check
```

## Usage

```
/legal-check                      # whole project, current directory
/legal-check ./apps/web           # another folder (e.g. one app in a monorepo)
/legal-check email                # only the email check
/legal-check このアプリ大丈夫？     # report in Japanese
```

## Example

This is real output on [`examples/vibely-sample`](examples/vibely-sample), a small Next.js app built to contain all six traps. The full run is in [`examples/`](examples/).

```
legal-check · vibely · 8 RISK · 0 PASS · 0 N/A

 #  Check                          Status  Where
 1  Kids under 13 (COPPA)          RISK    app/signup/page.tsx:28
 2  Google Fonts CDN (GDPR, EU)    RISK    app/layout.tsx:14
 3  Session replay (CIPA)          RISK    app/providers.tsx:15
 4  Marketing email (CAN-SPAM)     RISK    emails/launch-announcement.ts:4
 5  Subscriptions (CA auto-renew)  RISK    app/pricing/page.tsx:19
 6  User uploads (DMCA)            RISK    app/api/avatar/route.ts:11
 7  Privacy policy & terms         RISK    -
 8  Analytics consent              RISK    app/providers.tsx:9

── 2 · Google Fonts CDN (GDPR, EU) · RISK
Found: app/layout.tsx:14-18. Inter is loaded from fonts.googleapis.com and fonts.gstatic.com.
Risk:  A German court (LG München I, 20 Jan 2022) awarded one visitor €100 because loading
       Google Fonts sent his IP address to Google. This matters if you have EU visitors.
Fix:   Switch to next/font/google, which serves the font from your own domain. Remove the
       CDN <link> tags.
...
Apply the code fixes? (yes / no / only some numbers, e.g. "1 3")
```

After `yes`, it edited 21 files. `npm run typecheck` and `npm run build` still passed. It ended with:

```
Human TODO (code can't do these)
 [ ] Put your real postal address in the email footer (CAN-SPAM).
 [ ] Set UNSUBSCRIBE_SECRET, COMPANY_POSTAL_ADDRESS and NEXT_PUBLIC_APP_URL in your host.
 [ ] Register a DMCA designated agent at dmca.copyright.gov ($6, renew every 3 years)...
 [ ] Turn on cancellation in the Stripe Customer Portal settings.
 [ ] Have a lawyer review the privacy policy, terms, renewal terms, and DMCA page.
 ...
```

The applied diff is in [`examples/01-vibely-en.fixes.patch`](examples/01-vibely-en.fixes.patch).

On the clean control app [`examples/tidy-sample`](examples/tidy-sample), the same skill reports `0 RISK · 5 PASS · 3 N/A` and changes nothing.

## Time and cost

| Step | Wall time | Cost at API list prices |
|---|---|---|
| Audit (turn 1) | 24–47 s | $0.45–0.60 |
| Apply fixes (turn 2, 8 fixes, ~20 files) | 147–164 s | $1.23–1.31 |

These figures come from the runs in `examples/RUNS.md`, on Claude Code 2.1.283 with Opus 5.5 as the main model. On a Pro or Max plan, a run counts toward your usage limits and has no separate charge.

The audit does not use subagents. A parallel variant with one subagent per check took 75 s and cost $2.66, against 39 s and $0.57 for the design used here. The bundled scanner already collects the evidence in about a second.

## What the legal claims are based on

The skill uses these framings and is told not to go beyond them.

- **COPPA** applies if a service is directed to children under 13, or if the operator has actual knowledge that a user is under 13. The civil penalty is up to $53,088 per violation (the 2025 level). A general-audience site is not required to investigate ages.
- **Google Fonts.** In LG München I, 20 Jan 2022, 3 O 17493/20, a German court awarded one plaintiff €100 because a site disclosed his IP address to Google by loading Google Fonts from Google's servers.
- **Session replay.** Cal. Penal Code §631 is the wiretap provision, and §637.2 allows $5,000 per violation. The "per session" math is the plaintiffs' theory. In Popa v. Microsoft (9th Cir. 2025), the court found no standing in one case. PostHog and Microsoft Clarity mask inputs by default. LogRocket records non-password inputs by default.
- **CAN-SPAM** (15 U.S.C. §7704): commercial email needs a working opt-out and a valid physical postal address. The penalty is up to $53,088 per email.
- **California Automatic Renewal Law** (Bus. & Prof. Code §17602, as amended by AB 2863, for contracts from 1 July 2025) requires three things: clear and conspicuous terms in visual proximity to the subscribe button, affirmative consent, and easy online cancellation. The FTC click-to-cancel rule was vacated by the 8th Circuit on 8 July 2025.
- **DMCA** §512(c)(2): to keep safe harbor, designate an agent with the U.S. Copyright Office ($6, renew every 3 years) and post the agent's contact details on your site.

## Limitations

- **It is pattern matching plus judgment, not a legal review.** It can miss things. Examples: a font CDN pulled in by a third-party widget, an email template built by a no-code tool, or a subscription sold through an app store. Only the eight listed traps are checked. Accessibility (ADA), state privacy laws (CCPA/CPRA and others), GDPR beyond fonts and consent, taxes, and export rules are **not** covered.
- **Judgment calls can differ from run to run.** Examples: whether an app is "directed to children", or whether an email is commercial. The report states its assumption in those cases. Across our runs, the 8 statuses never changed, but the wording and line numbers did.
- **Fixes are drafts.** The generated privacy policy, terms, and DMCA page are starting points full of `TODO(legal-check)` placeholders. The Stripe cancel button needs the customer ID saved after checkout, and the fix tells you when it can't do that for you.
- **It can't do the human steps:** your postal address, DMCA agent registration, dashboard settings (Stripe portal, replay masking), and a lawyer's review.
- **It is tested on Next.js.** The scanner covers Vite/React, Supabase, Firebase, Clerk, FastAPI, Django, and plain HTML patterns (in `tests/test_scan.sh`), but the end-to-end fix runs were on a Next.js sample only.
- **Windows:** the scanner is a bash script. Use WSL or Git Bash.
- The legal numbers and cases are as of September 2026. Penalty amounts are adjusted for inflation.

## Development

```bash
bash tests/test_scan.sh                          # scanner unit tests (fixtures in examples/)
claude plugin validate .                         # marketplace manifest
claude plugin validate ./plugins/legal-check     # plugin manifest
```

End-to-end run with evidence. It uses two turns: the audit, then "yes". Run it on a copy, because turn 2 edits files.

```bash
cp -R examples/vibely-sample /tmp/vibely && cd /tmp/vibely && npm install
claude -p "/legal-check" --plugin-dir ~/ship-legal/plugins/legal-check \
  --output-format stream-json --verbose > turn1.jsonl
SID=$(tail -1 turn1.jsonl | python3 -c "import json,sys;print(json.load(sys.stdin)['session_id'])")
claude -p "yes" --resume "$SID" --plugin-dir ~/ship-legal/plugins/legal-check \
  --permission-mode acceptEdits --allowedTools "Bash(npm run typecheck)" "Bash(npm run build)" \
  --output-format stream-json --verbose > turn2.jsonl
python3 ~/ship-legal/tests/inspect_run.py turn1.jsonl turn2.jsonl \
  --expect RISK,RISK,RISK,RISK,RISK,RISK,RISK,RISK --transcript run.md
```

## License

MIT. See [LICENSE](LICENSE). Written from scratch.
