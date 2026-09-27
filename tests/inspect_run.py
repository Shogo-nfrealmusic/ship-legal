#!/usr/bin/env python3
"""Inspect `claude -p --output-format stream-json --verbose` logs of a /legal-check run.

Usage:
  python3 tests/inspect_run.py TURN1.jsonl [TURN2.jsonl] [--risk S1,S2,...] [--no-risk]
                               [--check K2,...] [--transcript OUT.md]

  --risk IDS   these check IDs must appear as RISK rows in turn 1 (others may too)
  --no-risk    turn 1 must contain no RISK rows at all (clean sample)
  --check IDS  these IDs must appear on the CHECK line

Checks:
  turn 1: read-only (no Edit/Write), summary has the counts line, expected RISK rows,
          disclaimer, ends by asking to apply fixes when there is a RISK,
          no secret-looking value printed
  turn 2: files were edited, "Human TODO" and disclaimer present
Prints duration (duration_ms) and cost per turn (total_cost_usd, API list prices).
"""
import json
import re
import sys

IDS = r"(S[1-5]|P[1-7]|K[12]|M[1-3]|\$[12]|C[1-4]|A1)"
ROW = re.compile(r"^\s*" + IDS + r"\s+(High|Medium|Low)\s+\S", re.M)
CHECK_LINE = re.compile(r"^\s*CHECK\s+(.*)$", re.M)
COUNTS = re.compile(r"(\d+)\s*RISK.*?(\d+)\s*CHECK.*?(\d+)\s*PASS.*?(\d+)\s*N/A")
EDIT_TOOLS = {"Edit", "Write", "MultiEdit", "NotebookEdit"}
SECRETISH = re.compile(r"sk_live_[A-Za-z0-9]{6,}|sk-proj-[A-Za-z0-9-]{8,}|patFAKE[a-z0-9]{6,}|key-FAKEdemo0")
DISCLAIMER = re.compile(r"not legal advice|法的助言では(ありません|ない)|法律相談では(ありません|ない)", re.I)


def load(path):
    return [json.loads(l) for l in open(path, encoding="utf-8") if l.strip().startswith("{")]


def summarize(events):
    texts, tools, result = [], [], None
    for e in events:
        if e.get("type") == "assistant" and not e.get("parent_tool_use_id"):
            for c in e["message"].get("content", []):
                if c.get("type") == "text" and c["text"].strip():
                    texts.append(c["text"].strip())
                elif c.get("type") == "tool_use":
                    tools.append(c)
        elif e.get("type") == "result":
            result = e
    return texts, tools, result


def take(args, flag, has_value=True):
    if flag not in args:
        return None
    i = args.index(flag)
    if has_value:
        v = args[i + 1]
        del args[i:i + 2]
        return v
    del args[i]
    return True


def main():
    args = sys.argv[1:]
    out = take(args, "--transcript")
    risk = take(args, "--risk")
    checks = take(args, "--check")
    no_risk = take(args, "--no-risk", has_value=False)
    if not args:
        print(__doc__)
        sys.exit(2)
    ok = True

    def check(cond, msg):
        nonlocal ok
        print(("  ok   - " if cond else "  FAIL - ") + msg)
        ok = ok and bool(cond)

    md = []
    for n, path in enumerate(args, 1):
        texts, tools, result = summarize(load(path))
        final = (result or {}).get("result", "") or ""
        alltext = "\n".join(texts) + "\n" + final
        dur = (result or {}).get("duration_ms", 0) / 1000
        cost = (result or {}).get("total_cost_usd", 0)
        denials = (result or {}).get("permission_denials", [])
        print(f"turn {n}: {path}")
        print(f"  duration {dur:.0f} s, cost ${cost:.2f} (list price), tool calls {len(tools)}, "
              f"subagents {sum(1 for t in tools if t['name'] in ('Agent', 'Task'))}, "
              f"permission denials {len(denials)}")
        for d in denials:
            print(f"    denied: {d.get('tool_name')} {json.dumps(d.get('tool_input'))[:120]}")
        edits = [t for t in tools if t["name"] in EDIT_TOOLS]
        check(not SECRETISH.search(alltext), "no secret value printed")
        if n == 1:
            check(not edits, "turn 1 is read-only (no Edit/Write)")
            rows = ROW.findall(final)
            got = {i for i, _ in rows}
            print(f"    RISK rows: {' '.join(f'{i}:{p[0]}' for i, p in rows) or '(none)'}")
            m = CHECK_LINE.search(final)
            print(f"    CHECK line: {m.group(1).strip()[:120] if m else '(none)'}")
            check(COUNTS.search(final), "counts line (RISK · CHECK · PASS · N/A)")
            if no_risk:
                check(not rows, "no RISK rows (clean sample)")
            if risk:
                for i in risk.split(","):
                    check(i in got, f"{i} reported as RISK")
            if checks:
                line = m.group(1) if m else ""
                for i in checks.split(","):
                    check(i in line, f"{i} on the CHECK line")
            check(DISCLAIMER.search(final), "disclaimer present")
            if rows:
                lines = [l for l in final.strip().splitlines() if l.strip() and not l.strip().startswith("```")]
                last = lines[-1]
                check(re.search(r"[?？)）]\s*$", last), "ends by asking whether to apply fixes")
        else:
            check(edits, f"turn {n} edited files ({len(edits)} edits)")
            check(re.search(r"Human TODO", final), "Human TODO list present")
            check(DISCLAIMER.search(final), "disclaimer present")
        md.append(f"## Turn {n}\n\nDuration {dur:.0f} s · cost ${cost:.2f} at API list prices · "
                  f"{len(tools)} tool calls\n\n" + "\n\n".join(texts) + "\n")
    if out:
        with open(out, "w", encoding="utf-8") as f:
            f.write("\n".join(md))
        print(f"transcript written to {out}")
    print("RESULT:", "all checks pass" if ok else "FAILED")
    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()
