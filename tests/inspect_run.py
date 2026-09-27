#!/usr/bin/env python3
"""Inspect `claude -p --output-format stream-json --verbose` logs of a /legal-check run.

Usage:
  python3 tests/inspect_run.py TURN1.jsonl [TURN2.jsonl] --expect SPEC [--transcript OUT.md]

SPEC is 8 comma-separated statuses in check order, e.g.
  RISK,RISK,RISK,RISK,RISK,RISK,RISK,RISK      (vibely-sample)
  PASS,PASS,PASS,N/A,N/A,N/A,PASS,PASS          (tidy-sample)
Use * for "any status".

Checks:
  turn 1: read-only (no Edit/Write/NotebookEdit), summary table has 8 rows matching SPEC,
          disclaimer present, ends by asking to apply fixes when there is a RISK
  turn 2: files were edited, "Human TODO" list and disclaimer present
Prints wall time and cost per turn (cost = Claude Code's total_cost_usd, API list prices).
"""
import json
import re
import sys

ROW = re.compile(r"^\s*([1-8])\s+.+?\s(PASS|RISK|N/A)\b", re.M)
EDIT_TOOLS = {"Edit", "Write", "MultiEdit", "NotebookEdit"}


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


def main():
    args = sys.argv[1:]
    out = None
    spec = None
    if "--transcript" in args:
        i = args.index("--transcript"); out = args[i + 1]; del args[i:i + 2]
    if "--expect" in args:
        i = args.index("--expect"); spec = args[i + 1].split(","); del args[i:i + 2]
    if not args or spec is None or len(spec) != 8:
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
        final = result.get("result", "") if result else ""
        dur = (result or {}).get("duration_ms", 0) / 1000
        cost = (result or {}).get("total_cost_usd", 0)
        denials = (result or {}).get("permission_denials", [])
        print(f"turn {n}: {path}")
        print(f"  wall {dur:.0f} s, cost ${cost:.2f} (list price), tool calls {len(tools)}, "
              f"subagents {sum(1 for t in tools if t['name'] in ('Agent', 'Task'))}, "
              f"permission denials {len(denials)}")
        for t in tools:
            if t["name"] == "Bash":
                print(f"    bash: {t['input'].get('command', '')[:110]}")
        edits = [t for t in tools if t["name"] in EDIT_TOOLS]
        if n == 1:
            check(not edits, "turn 1 is read-only (no Edit/Write)")
            rows = ROW.findall(final)
            got = [s for _, s in sorted({int(k): s for k, s in rows}.items())]
            check(len(got) == 8, f"summary table has 8 rows (got {len(got)})")
            for i, (g, want) in enumerate(zip(got, spec), 1):
                check(want == "*" or g == want, f"check {i}: {g} (expected {want})")
            check(re.search(r"not legal advice|法的助言では(ありません|ない)", final, re.I), "disclaimer present")
            if "RISK" in got:
                check(re.search(r"\?\s*$|？\s*$|\)\s*$|）\s*$", final.strip().splitlines()[-1]),
                      "ends by asking whether to apply fixes")
        else:
            check(edits, f"turn {n} edited files ({len(edits)} edits)")
            check(re.search(r"Human TODO", final), "Human TODO list present")
            check(re.search(r"not legal advice|法的助言では(ありません|ない)", final, re.I), "disclaimer present")
        md.append(f"## Turn {n}\n\nWall time {dur:.0f} s · cost ${cost:.2f} at API list prices · "
                  f"{len(tools)} tool calls\n\n" + "\n\n".join(texts) + "\n")
    if out:
        with open(out, "w", encoding="utf-8") as f:
            f.write("\n".join(md))
        print(f"transcript written to {out}")
    print("RESULT:", "all checks pass" if ok else "FAILED")
    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()
