# Test runs (v2)

Every run is end-to-end and non-interactive (`claude -p ... --output-format stream-json --verbose`):

- **Turn 1** is the audit.
- **Turn 2** resumes the same session with `yes` in `acceptEdits` mode (edits don't need a prompt). The project's check commands are pre-allowed: `npm run *`, `.venv/bin/pytest`, `node --check`, `grep -rn`.

Each run was then checked with `tests/inspect_run.py`, and the builds and tests were re-run by hand on the patched copy.

Setup: Claude Code 2.1.283, main model Opus 5.5, all on 2026-09-28. Wall time was measured outside Claude. Cost is `total_cost_usd`, which prices tokens at API list prices; these runs used a Max plan, so nothing was charged. Every run used the final `SKILL.md`, except for the one qualifier line added after these runs.

| Sample (stack) | Turn 1 audit | Turn 2 apply | Build / tests after fixes (re-run by hand) |
|---|---|---|---|
| `lovable-vite-supabase` (Vite React + Supabase, Lovable) | 54 s · $0.68 · 14 RISK (4 High) | 292 s · $1.95 · 27 files | `npm run build` ✓ |
| same, in Japanese | 61 s · $0.68 · same 14 RISK, report in Japanese | 348 s · $2.13 · 30 files | `npm run build` ✓ |
| `html-stripe-landing` (plain HTML + Stripe Payment Link, Bolt) | 41 s · $0.59 · 11 RISK (4 High) | 158 s · $1.26 · 9 files | `node --check` on all JS ✓ |
| `expo-firebase-app` (Expo RN + Firebase + Twilio) | 44 s · $0.62 · 11 RISK (5 High), CHECK: K2 | 213 s · $1.47 · 14 files | `tsc --noEmit` ✓, `node --check functions/index.js` ✓ |
| `fastapi-shop` (FastAPI + Jinja, Replit) | 46 s · $0.64 · 12 RISK (3 High) | 197 s · $1.49 · 19 files | `pytest` 2/2 ✓, `compileall` ✓ |
| `vibely-sample` (Next.js) | 62 s · $0.71 · 13 RISK (2 High) | 308 s · $1.91 · 32 files | `npm run typecheck` ✓, `npm run build` ✓ |
| `clean-vite-supabase` (clean control) | 43 s · $0.54 · **0 RISK**; CHECK: DMCA agent placeholder details | — | — |
| `tidy-sample` (clean Next control) | 30 s · $0.51 · **0 RISK** | — | — |

The inspector confirmed four things on every run:

- turn 1 made no edits;
- the report included the expected RISK IDs (e.g. S1, S2, S3, P2, C4, A1 on the Lovable sample);
- the disclaimer was there, and turn 1 ended with the one question;
- turn 2 had a Human TODO list, and no secret value appeared anywhere in the output.

There were no permission denials in any final run.

## Seeded traps and what came back

- **Lovable (Vite + Supabase):**
  - OpenAI key behind `VITE_`, with `.env` committed → S1
  - tables with no RLS and a public bucket → S2
  - `/admin` lists every email using the anon key → S3
  - Meta Pixel → P2 and P7
  - no policies → P5
  - no account deletion → P6
  - no age screen → K1
  - invented testimonials → M3
  - public photo posts → C1 and C2
  - bot told to deny being an AI → C4
  - missing alt text, missing labels, clickable div, zoom disabled, outline removed → A1
  - Google Fonts → P4
- **HTML + Stripe link:**
  - Airtable token in client JS → S1
  - Hotjar → P1
  - GA, Google Ads and TikTok pixels → P2, P3 and P7
  - phone field for "SMS tips" with no consent → M2
  - Payment Link with no renewal terms → $1
  - no refund policy → $2
  - accessibility problems → A1
  - Google Fonts → P4
  - no policies → P5
  - M1 came back as CHECK, because the newsletter is sent outside the repo.
- **Expo + Firebase:**
  - `EXPO_PUBLIC_OPENAI_API_KEY` → S1
  - test-mode Firestore rules and open Storage rules → S2
  - daily promo texts via Twilio with no written consent → M2
  - no in-app deletion → P6
  - public photo feed with no report/block → C2
  - "InstaVibe" name → C3
  - K2 came back as CHECK.
- **FastAPI:**
  - hard-coded `sk_live_` and Mailgun keys → S1
  - `/admin/orders` open → S3
  - card number, expiry and CVC stored in SQLite → S4
  - SHA-256 passwords with no rate limit → S5
  - promo email with no unsubscribe or address → M1
  - public uploads with no DMCA page → C1
  - service fee not in the advertised price → $2
- **Clean controls:** no RISK. Three things in them were correctly not reported:
  - "continue with Google" (not a trademark problem);
  - the Supabase anon key (public by design);
  - the service-role key inside an Edge Function (server-side).

## Scanner speed

`scan.sh` runs its checks in parallel.

| Project | Source files | Scan time |
|---|---|---|
| Real local repos (Next + Supabase) | 60–150 | 2–7 s |
| A Python project | 650 | 14 s |
| Generated tree (in `tests/test_scan_v2.sh`) | 3,000 | 4 s |

Before parallelizing, the 650-file project took 44 s.

## Independent reviews

Two fresh reviewer subagents checked the work.

- **v1:** 0 Critical, 9 Important; all fixed.
- **v2:** 1 Critical: secrets could appear unredacted in keys other than `secrets`. 6 Important:
  - a false claim in a Human TODO;
  - a rate limiter that would lock out everyone behind a proxy;
  - admin checks that ignored middleware and hooks;
  - a permission prompt in turn 2;
  - invented settings text;
  - wording on Texas, Utah and the EU.

  All were fixed, with regression tests for the scanner parts. On the Texas and Utah wording, the reviewer was working from memory (about 70% confidence). The researcher's primary sources (5th Circuit stay; Utah HB 498) were kept.

## Earlier runs

The v1 runs (8 checks, Next.js only) are in [`../v1/`](../v1/).
