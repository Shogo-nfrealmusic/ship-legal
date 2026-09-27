# Recording a demo

## Setup

```bash
git clone https://github.com/Shogo-nfrealmusic/ship-legal.git ~/ship-legal
cp -R ~/ship-legal/examples/vibely-sample ~/Desktop/vibely
cd ~/Desktop/vibely && npm install
git init -q && git add -A && git commit -qm before   # so you can reset between takes
```

- Start `claude` once in `~/Desktop/vibely` and accept the trust dialog, so it doesn't appear on camera.
- Install the skill (see the README), or start with `claude --plugin-dir ~/ship-legal/plugins/legal-check`.
- Make the terminal at least 100 columns wide, since report lines run up to about 90 characters.
- Between takes, run `git reset --hard && git clean -fd`. It restores the "before" state and leaves `node_modules` alone, because that folder is git-ignored.

## The command

```
/legal-check
```

Japanese version, for a Japanese-language cut:

```
/legal-check このアプリ、法的に大丈夫？
```

## What the viewer sees

1. **0–5 s:** the skill starts and runs `scan.sh`, then a few file reads. No permission prompts appear.
2. **About 40 s:** the report appears:
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
   ```
   Then comes one block per risk (Found / Risk / Fix), and at the end: `Apply the code fixes? (yes / no / only some numbers, e.g. "1 3")`. The table is the hook shot.
3. Press **Shift+Tab** until the footer says "accept edits", then type `yes`.
4. **About 2.5 min:** it edits about 20 files, then runs `npm run typecheck` and `npm run build`. **Speed this up in the edit.** `npm run build` asks for approval once unless you pre-allow it.
5. **Ending:** the `Applied ✓` list, then `Human TODO` (postal address, DMCA registration at dmca.copyright.gov, Stripe portal setting, lawyer review), and the "Not legal advice" line.

Line numbers and exact wording vary a little from run to run. The eight statuses did not vary in any of our runs.

Reference output: `examples/01-vibely-en.md`.

## VHS tape (audit only)

```tape
Output legal-check.mp4
Set FontSize 18
Set Width 1400
Set Height 900
Set Theme "Dracula"
Set TypingSpeed 35ms

Type "cd ~/Desktop/vibely && claude"
Enter
Sleep 5s
Type "/legal-check"
Sleep 500ms
Enter
Sleep 60s
```

`Sleep 60s` covers the observed 35–47 s audit plus a margin.

To record the fix turn as well, start Claude with `claude --permission-mode acceptEdits` in the tape, so no edit prompts appear. Then after the report, add `Type "yes"`, `Enter`, and `Sleep 200s`, and trim the wait in post. `npm run build` may still ask once. Answer it with `Enter`, or pre-allow `Bash(npm run build)` in the project's `.claude/settings.local.json`.
