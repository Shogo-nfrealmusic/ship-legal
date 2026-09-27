# Test runs

Every run is end-to-end and non-interactive (`claude -p ... --output-format stream-json --verbose`), and each is checked with `tests/inspect_run.py`. Turn 2 resumes the same session with `--resume`, in `acceptEdits` mode, and pre-approves `npm run typecheck` and `npm run build`. Setup: Claude Code 2.1.283, main model Opus 5.5.

Wall time is measured outside Claude with `date`. Cost is Claude Code's `total_cost_usd`, which prices token usage at **API list prices**. These runs were on a Max subscription, so no money was charged. The session carried a large MCP and tool setup, and a lighter setup should cost less.

| File | Sample | Prompt | Turn 1 (audit) | Turn 2 (apply) | Inspector |
|---|---|---|---|---|---|
| `01-vibely-en.md` + `.fixes.patch` | vibely-sample | `/legal-check` → `yes` | 39 s · $0.57 · 8/8 RISK | 156 s · $1.29 · typecheck ✓ build ✓ | all checks pass |
| `02-vibely-ja.md` + `.fixes.patch` | vibely-sample | `/legal-check このアプリ、法的に大丈夫？` → `はい、お願いします` | 46 s · $0.60 · 8/8 RISK, report in Japanese | 161 s · $1.31 · typecheck ✓ build ✓ | all checks pass |
| `03-tidy-clean.md` | tidy-sample (clean control) | `/legal-check` | 24 s · $0.45 · 0 RISK, 5 PASS, 3 N/A | (nothing to apply) | all checks pass |
| `04-tidy-copy-install.md` | tidy-sample, skill copied into the project's `.claude/skills/` (no `--plugin-dir`) | `/legal-check` | 27 s · $0.47 · 0 RISK, 5 PASS, 3 N/A; the skill's own recipe files were not reported | (nothing to apply) | all checks pass |

Run 02 used the version just before the final one. The only change since then is the `grep` fallback, which affects turn 2's verification step only. Runs 01 and 03 use the final `SKILL.md`, except that 03 was made before the same `grep` change, which it doesn't use.

## Checked independently after turn 2 (run 01)

- `npm run typecheck` passes, and so does `npm run build` (16 routes).
- No `fonts.googleapis.com`, `fonts.gstatic.com`, or `maskAllInputs: false` is left in the source.
- PostHog's `init` runs only inside `acceptTracking()`, after the visitor clicks Accept.
- `GET /api/unsubscribe` only shows a confirm button. `POST` does the unsubscribe after checking an HMAC token (a signed code, so nobody can unsubscribe someone else).
- The postal address, company name, and DMCA agent are `TODO(legal-check)` placeholders. None were invented.

## Interactive check

The same audit was run in the real terminal UI with `claude --plugin-dir ... --permission-mode default`, driven by `expect`. The question "Apply the code fixes?" appeared after about **47 s**, with **no permission prompts** during the audit. The audit turn uses only `scan.sh`, which the skill pre-approves, and the Read tool.

In turn 2, default permission mode asks once for each file edit (about 20 edits on vibely-sample). Switch to "accept edits" first (Shift+Tab) if you don't want to approve each one.

## Why no parallel subagents

We measured one variant that sent 8 Explore subagents in parallel, one per check, to confirm the evidence. It found the same 8/8 RISK, but turn 1 took **75 s and cost $2.66**. The single-session design took **39 s and cost $0.57**. The shell scanner already gathers the evidence in about a second, so the model only needs a few targeted reads. Subagents would each start cold and re-read the same files.

## Earlier runs (before review fixes)

- First version: 39 s · $0.56 for the audit, 164 s · $1.31 for the fixes. Correct results, but 3 Bash calls were denied: a `cat` in the audit, and a piped typecheck and a scanner re-run in the fix turn. The tool rules at the top of `SKILL.md` came from this. The next runs had no denials.
