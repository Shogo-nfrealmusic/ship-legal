# Recording a demo

The demo sample is `examples/lovable-vite-supabase`, a Lovable-style React + Vite + Supabase app. It makes the strongest screen: 14 RISK, 4 of them High (exposed OpenAI key, open database, open admin page, Meta Pixel without consent).

## Setup

```bash
git clone https://github.com/Shogo-nfrealmusic/ship-legal.git ~/ship-legal
cp -R ~/ship-legal/examples/lovable-vite-supabase ~/Desktop/chatfit
cd ~/Desktop/chatfit && npm install
git init -q && git add -A && git commit -qm before   # lets you reset between takes
```

Before you record:

- Start `claude` in `~/Desktop/chatfit` once and accept the trust dialog, so it doesn't appear on camera.
- Install the skill (see the README), or start Claude with `claude --plugin-dir ~/ship-legal/plugins/legal-check`.
- Make the terminal at least 100 columns wide. Report lines run up to about 90 characters.
- Between takes, run `git reset --hard && git clean -fd`. It restores the "before" state and leaves `node_modules` alone, because it's git-ignored.
- The keys in `.env` are fake. The scanner redacts them anyway, so no key value appears on screen.

## The command

```
/legal-check
```

For a Japanese cut:

```
/legal-check このアプリ、訴えられるリスクある？
```

## What the viewer sees

1. **0–5 s:** the skill runs `scan.sh`, then a few file reads. No permission prompts appear during the audit.
2. **About 50–60 s:** the report appears:
   ```
   legal-check · chatfit · vite-react + supabase (lovable)
   14 RISK (4 High) · 0 CHECK · 0 PASS · 10 N/A

    ID  Risk    Check                               Where
    S1  High    Secret keys exposed                 .env:3
    S2  High    Database open to anyone             supabase/migrations/…_init.sql:1
    S3  High    Admin area without auth             src/pages/Admin.tsx:8
    P2  High    Ad pixels without consent           index.html:10
    ...
   ```
   Then comes one Found / Risk / Fix block per risk, and at the end: `Apply the code fixes? (yes / no / only some IDs, e.g. "S1 S2 A1")`. The first four High rows are the hook shot.
3. Press **Shift+Tab** until the footer says "accept edits", then type `yes`.
4. **About 5 min:** it edits about 27 files, then runs `npm run typecheck` and `npm run build`. **Speed this up in the edit.** `npm run build` may ask for approval once. Press Enter.
5. **Ending:** the `Applied ✓` list, then `Human TODO` (rotate the OpenAI key, apply the RLS migration, deploy the Edge Functions, DMCA registration, lawyer review), and the "Not legal advice" line.

Line numbers, wording, and a few Medium/Low rows vary from run to run. The four High rows appeared in every run.

Reference output: `examples/runs/lovable-vite-supabase.md`.

## VHS tape (audit only)

```tape
Output legal-check.mp4
Set FontSize 18
Set Width 1400
Set Height 900
Set Theme "Dracula"
Set TypingSpeed 35ms

Type "cd ~/Desktop/chatfit && claude"
Enter
Sleep 5s
Type "/legal-check"
Sleep 500ms
Enter
Sleep 75s
```

`Sleep 75s` covers the observed 51–61 s audit plus a margin.

To record the fix turn too:

1. Start with `claude --permission-mode acceptEdits` in the tape, so no edit prompts appear.
2. After the report, add `Type "yes"`, `Enter`, and `Sleep 360s`.
3. Trim the wait in post.

`npm run build` may still ask for approval once. To avoid that, pre-allow `Bash(npm run build)` in the project's `.claude/settings.local.json`.
