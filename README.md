# legal-check for Claude Code

`/legal-check` audits a vibe-coded web or mobile app for the things most likely to get it sued, fined, breached, or rejected from the App Store. Then it fixes what code can fix, in your app's own stack.

```
/legal-check
```

**This is not legal advice.** It's an automated check of common traps, not a full legal review, and it can miss things. Have a lawyer review your policies and flows before you rely on them.

## What it checks

23 checks, reported by risk (High → Medium → Low).

| Group | Checks |
|---|---|
| **Security that creates liability** | S1 secret keys in client code or git · S2 open database (Supabase RLS off, Firebase test-mode rules, public buckets) · S3 admin routes with no auth · S4 raw card data on your server (PCI) · S5 login rate limits and password hashing |
| **Privacy & tracking** | P1 session replay (California wiretap law) · P2 ad pixels (Meta, TikTok, Google Ads…) before consent · P3 analytics cookies without EU consent · P4 Google Fonts from Google's servers (GDPR) · P5 privacy policy and terms (CalOPPA, CCPA content, liability terms, clickwrap) · P6 account deletion and data export (GDPR, CCPA, App Store) · P7 "Do Not Sell or Share" and Global Privacy Control (CCPA) |
| **Kids** | K1 kids under 13 (COPPA) · K2 app-store age ratings |
| **Marketing** | M1 marketing email (CAN-SPAM) · M2 marketing texts (TCPA) · M3 testimonials and claims (FTC) |
| **Payments** | $1 subscriptions (California auto-renewal law) · $2 refund policy and price clarity (drip pricing) |
| **Content & IP** | C1 user uploads (DMCA) · C2 report and block for user content (App Store 1.2, TAKE IT DOWN Act) · C3 trademarks in your app name or claims · C4 AI disclosure (EU AI Act Art. 50, California bot law) |
| **Accessibility** | A1 alt text, form labels, keyboard access, focus outlines, zoom, `lang` (ADA/WCAG) |

Each check comes back as one of four statuses:

- **RISK:** the code shows the problem. It gets a priority.
- **CHECK:** only a human can settle it, e.g. whether a testimonial is real, or a dashboard setting.
- **PASS:** handled.
- **N/A:** the feature isn't there.

## Works across stacks

The scan detects your stack first, then fixes with that stack's idioms. Where no recipe note fits, Claude makes the same change following your project's own patterns instead of skipping the fix.

| | Detected | Tested end to end (scan + fix + build/tests) |
|---|---|---|
| Next.js | ✓ | ✓ `examples/vibely-sample` |
| React + Vite (Lovable / Bolt style) + Supabase | ✓ | ✓ `examples/lovable-vite-supabase` |
| Plain HTML/JS + Stripe Payment Link (Bolt export) | ✓ | ✓ `examples/html-stripe-landing` |
| Expo / React Native + Firebase | ✓ | ✓ `examples/expo-firebase-app` |
| FastAPI (Replit) | ✓ | ✓ `examples/fastapi-shop` |
| Vue / Nuxt, SvelteKit, Astro, Remix, Flask, Django, Rails, v0 exports | ✓ | detection and scanner tests only |

Clean controls (should report no RISK): `examples/tidy-sample` (Next.js) and `examples/clean-vite-supabase` (Vite + Supabase).

## How it works

1. **Scan (read-only).** A bundled shell script detects the stack, then collects evidence as `file:line` for every check. It skips `node_modules`, build output, lockfiles, and files over 1 MB, and it redacts secret values. In our tests it took 0–14 s per project.
2. **Judge.** Claude reads only the files the scan points at, then applies fixed rules. For example, a password-reset email is transactional, so CAN-SPAM's unsubscribe rule doesn't apply. The Supabase anon key is public by design and isn't reported.
3. **Report, then ask once.** You get the summary table first, then one short block per RISK (Found / Risk / Fix), then one question: apply the fixes?
4. **Fix.** This only happens after you say yes. It edits your code. It never runs installs, migrations, deploys, or git commits. Then it runs your project's own checks: `npm run build`/`typecheck`/`test`, `pytest`, `node --check`, …
5. **Human TODO.** A list of what code can't do. For example: rotate leaked keys, apply the new database rules, add your postal address, register a DMCA agent, answer the app-store rating questionnaires, get a lawyer's review.

## Install

### Option A: as a plugin (recommended)

In Claude Code:

```
/plugin marketplace add Shogo-nfrealmusic/ship-legal
/plugin install legal-check@ship-legal
```

Then run `/legal-check`. It also answers to `/legal-check:legal-check`.

### Option B: copy the skill folder

```bash
git clone https://github.com/Shogo-nfrealmusic/ship-legal.git
cp -R ship-legal/plugins/legal-check/skills/legal-check ~/.claude/skills/
```

To use it in one project only, copy the folder into that project's `.claude/skills/` instead. The scanner skips `.claude/`, so its own files are never reported.

### Try it without installing

```bash
claude --plugin-dir ./ship-legal/plugins/legal-check
```

Requirements: bash and grep (macOS or Linux; on Windows, use WSL or Git Bash). The scanner uses perl for its multi-line checks, and perl ships with macOS and almost every Linux. Without perl, those checks say "(perl missing)".

## Usage

```
/legal-check                        # whole project in the current directory
/legal-check ./apps/web             # another folder (e.g. one app in a monorepo)
/legal-check security               # only one group: security, privacy, kids, marketing,
                                    # payments, content, accessibility
/legal-check このアプリ大丈夫？       # report in Japanese
```

## Example

This is real output on `examples/lovable-vite-supabase`, a Lovable-style React + Vite + Supabase app built with seeded traps. The full runs are in [`examples/runs/`](examples/runs/).

EXAMPLE_PLACEHOLDER

## Time and cost

TIMECOST_PLACEHOLDER

## Limitations

- **It pattern-matches and then judges; it is not a legal review.** It can miss problems. For example:
  - a tracker injected by a tag manager or a third-party widget,
  - rules set in a vendor dashboard,
  - database tables created in the Supabase dashboard (reported as CHECK),
  - screens built at runtime.

  It also doesn't cover taxes, export controls, sector rules (health, finance, education), or most non-US laws beyond the EU items listed.
- **Some calls are judgment calls.** Examples: whether an app is "directed to children", whether an email is commercial, or whether a testimonial is real. The report states its assumption in those cases. Across our runs, the high-priority findings were stable, but wording and some lower-priority rows varied.
- **Fixes are drafts to review.**
  - Policy, terms, refund and DMCA pages are full of `TODO(legal-check)` placeholders.
  - New database rules and migrations are written but not applied.
  - New dependencies are added to the manifest but not installed.
- **Accessibility is only the mechanical basics.** Contrast is spot-checked, not measured. Run Lighthouse or axe and do a keyboard-only pass too.
- **End-to-end fix runs cover only five stacks.** They were Next.js, Vite + Supabase, plain HTML, Expo + Firebase, and FastAPI. For the other stacks, only detection and the scanner were tested.
- **The legal facts are as of September 2026.** Several areas are moving:
  - pixel lawsuits and California SB 690,
  - the Supreme Court's VPPA case,
  - FCC texting-consent rules,
  - state app-store laws.

## Legal sources (checked 2026-09-28)

Every one-line framing in the skill was checked against primary sources: statute text, the Federal Register, court opinions, regulator pages, and platform policies. The skill is told not to go beyond them. The key facts:

- **CCPA** applies to businesses over the $26.625M revenue threshold (as adjusted from 1 Jan 2025), or with data on 100k+ consumers, or earning 50%+ of revenue from selling/sharing data. Sending data to ad platforms is "sharing", and GPC must be honored.
- **Supabase:** tables in exposed schemas are readable and writable with the anon key unless RLS is on. CVE-2025-48757 reported that a 2025 scan found 170 of 1,645 Lovable apps exposed; Lovable disputes it.
- **PCI:** Stripe Checkout and Elements qualify you for SAQ A.
- **EU AI Act Art. 50** has applied since 2 Aug 2026.
- **TAKE IT DOWN Act:** the 48-hour removal duty has applied since 19 May 2026.
- **ADA:** about 3,117 federal website-accessibility suits were filed in 2025 (Seyfarth Shaw).
- **TCPA:** $500 per text, up to $1,500 if willful. STOP must be honored within 10 business days.
- **FTC:** the rule against fake reviews and testimonials has been in effect since 21 Oct 2024.
- **Apple:** in-app account deletion has been required since 30 Jun 2022. The new age ratings (13+/16+/18+) are in force.
- **State app-store laws:** Texas's is in force; Utah's starts 6 May 2027.

The v1 checks keep their earlier sources:

- COPPA: $53,088 per violation.
- LG München I, 3 O 17493/20: €100 for loading Google Fonts.
- Cal. Penal Code §631/§637.2 (session replay), and Popa v. Microsoft.
- CAN-SPAM, 15 U.S.C. §7704.
- Cal. Bus. & Prof. Code §17602 as amended by AB 2863. The FTC's click-to-cancel rule was vacated on 8 Jul 2025.
- DMCA §512(c)(2): designated agent, $6, renew every 3 years.

## 日本語での説明

`/legal-check` は、バイブコーディングで作った Web アプリやモバイルアプリを調べます。探すのは、訴訟・罰金・情報漏えい・App Store リジェクトにつながりやすい箇所です。コードで直せるものは、そのアプリの技術構成に合わせて直します。

- **何を見るか:** 23項目です。
  - API キーの露出
  - Supabase の RLS（行ごとのアクセス制限）が無効
  - 管理画面に認証がない
  - カード情報を自分のサーバーで扱っている
  - 同意なしの広告ピクセル
  - セッション録画
  - Cookie 同意
  - プライバシーポリシーと利用規約
  - アカウント削除
  - 13歳未満（COPPA）
  - 宣伝メール・SMS
  - 口コミ・誇大表示
  - サブスクの自動更新
  - 返金
  - 著作権（DMCA）
  - 投稿の通報・ブロック
  - 商標
  - AI であることの表示
  - アクセシビリティ（ADA）
- **使い方:**
  - `/legal-check` と入力します。日本語で `/legal-check このアプリ大丈夫？` と聞けば、報告も日本語になります。
  - 最初に要約の表が出て、その後に RISK（問題あり）の詳細が続きます。最後に「修正を適用しますか？」と1回だけ聞きます。
  - 「はい」と答えると修正して、ビルドやテストが通るか確認します。
- **人間がやること:** 最後に Human TODO として一覧で出ます。
  - 漏れたキーの再発行
  - DB ルールの適用
  - 住所の記入
  - DMCA 代理人の登録（$6）
  - 年齢レーティングの回答
  - 弁護士の確認
- **注意:** 法的助言ではありません。自動チェックなので見落としもあります。生成されるポリシーや規約は下書きで、`TODO(legal-check)` の印が付いています。
- **対応している構成:** Next.js、React+Vite（Lovable・Bolt）、素の HTML、Vue/Nuxt、SvelteKit、Astro、Remix、Expo（React Native）、Flask・FastAPI・Django、Rails、Supabase・Firebase です。修正まで最後まで試したのは、Next.js・Vite+Supabase・HTML・Expo+Firebase・FastAPI の5つです。

## Development

```bash
bash tests/test_scan.sh                          # scanner tests (v1 fixtures)
bash tests/test_scan_v2.sh                       # scanner tests (v2 stacks, recipes, speed)
claude plugin validate .                         # marketplace manifest
claude plugin validate ./plugins/legal-check     # plugin manifest
```

The end-to-end run takes two turns: the audit, then "yes". Do it on a copy, because turn 2 edits files:

```bash
cp -R examples/lovable-vite-supabase /tmp/app && cd /tmp/app && npm install
git init -q && git add -A && git commit -qm before
claude -p "/legal-check" --plugin-dir ~/ship-legal/plugins/legal-check \
  --output-format stream-json --verbose > turn1.jsonl
SID=$(tail -1 turn1.jsonl | python3 -c "import json,sys;print(json.load(sys.stdin)['session_id'])")
claude -p "yes" --resume "$SID" --plugin-dir ~/ship-legal/plugins/legal-check \
  --permission-mode acceptEdits --allowedTools "Bash(npm run *)" "Bash(grep -rn *)" \
  --output-format stream-json --verbose > turn2.jsonl
python3 ~/ship-legal/tests/inspect_run.py turn1.jsonl turn2.jsonl --risk S1,S2,S3 --transcript run.md
```

## License

MIT. See [LICENSE](LICENSE). Written from scratch.
