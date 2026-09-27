# Clean control: Next.js

Prompt: `/legal-check`

## Turn 1

Duration 27 s · cost $0.51 at API list prices · 10 tool calls

```
legal-check · tidy · next (no backend)
0 RISK (0 High) · 0 CHECK · 9 PASS · 15 N/A

PASS   S1 Secrets · S5 Rate limits & hashing · P1 Session replay · P3 Analytics
       consent · P4 Fonts · P5 Policy & terms · P6 Deletion & export · K1 Age
       screen · A1 Accessibility basics
N/A    S2 Database · S3 Admin · S4 Card data · P2 Ad pixels · P7 Do Not Sell ·
       K2 Age rating · M1 Email (reset only) · M2 SMS · M3 Testimonials ·
       $1 Subscriptions · $2 Refunds · C1 DMCA · C2 Report/block · C3 Trademarks ·
       C4 AI disclosure

Nothing to fix in code.

Human TODO
 [ ] In the PostHog dashboard, check that session recording keeps input masking on
 [ ] Run Lighthouse or axe and a keyboard-only pass (contrast wasn't checked)
 [ ] Write a one-page breach plan: who decides, who you notify, and by when
 [ ] Have a lawyer review the privacy policy and terms

Not legal advice — an automated check of common traps, not a full legal review.
```

Notes on the PASS items:
- **P1/P3:** PostHog doesn't load until someone clicks Accept (`lib/analytics.ts:8`). It keeps the default input masking, and the privacy policy names it.
- **K1:** The age screen lists every birth year without hinting at a minimum age. The server turns away anyone under 13 without storing their data, and a cookie blocks a retry with a different year (`app/api/signup/route.ts:18`).
- **S5:** Passwords are hashed with scrypt, and signup and password reset are rate-limited.
