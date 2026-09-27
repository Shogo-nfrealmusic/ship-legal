# 04-tidy-copy-install

Install: skill folder copied into the project's `.claude/skills/` (Option B). Prompt: `/legal-check`

## Turn 1

Wall time 25 s · cost $0.47 at API list prices · 10 tool calls

```
legal-check · copyinstall · 0 RISK · 5 PASS · 3 N/A

 #  Check                          Status  Where
 1  Kids under 13 (COPPA)          PASS    app/api/signup/route.ts:16
 2  Google Fonts CDN (GDPR, EU)    PASS    app/layout.tsx:3
 3  Session replay (CIPA)          PASS    lib/analytics.ts:11
 4  Marketing email (CAN-SPAM)     N/A     emails/password-reset.ts:1
 5  Subscriptions (CA auto-renewal) N/A    -
 6  User uploads (DMCA)            N/A     -
 7  Privacy policy & terms         PASS    app/layout.tsx:18
 8  Analytics consent              PASS    components/ConsentBanner.tsx:21

Notes
 1  The age screen is neutral: every birth year can be picked. Under-13 sign-ups are
    refused and nothing about them is stored, and only a 13+ flag is kept.
 2  next/font/google self-hosts Inter at build time, so visitors never contact Google.
 3  PostHog loads only after Accept and keeps its default input masking. The privacy
    page discloses recording. (I assumed masking isn't turned off in the PostHog dashboard.)
 4  The only email is the password reset, which is transactional.
 5  There's no recurring billing.
 6  Notes are private and nothing users write is shown to others.

Fixes I can apply now: none. Needs a human: have a lawyer review the privacy policy and
terms, and check PostHog's masking settings in its dashboard.
Not legal advice. This is an automated check of 8 common traps, not a full legal review.
```

None of the 8 checks found a risk, so there's no code to change. I didn't edit any files.
