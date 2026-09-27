# 03-tidy-clean

Prompt: `/legal-check`

## Turn 1

Wall time 21 s · cost $0.45 at API list prices · 9 tool calls

```
legal-check · tidy · 0 RISK · 5 PASS · 3 N/A

 #  Check                          Status  Where
 1  Kids under 13 (COPPA)          PASS    app/api/signup/route.ts:16
 2  Google Fonts CDN (GDPR, EU)    PASS    app/layout.tsx:3
 3  Session replay (CIPA)          PASS    lib/analytics.ts:11
 4  Marketing email (CAN-SPAM)     N/A     app/api/reset-password/route.ts:12
 5  Subscriptions (CA auto-renewal) N/A    -
 6  User uploads (DMCA)            N/A     -
 7  Privacy policy & terms         PASS    app/layout.tsx:18
 8  Analytics consent              PASS    components/ConsentBanner.tsx:14

Why each one passed or doesn't apply:
 1  Neutral age screen: all years selectable, under-13s are blocked and nothing is stored
 2  next/font/google serves the font from your own site, so no request goes to Google
 3  PostHog starts only after Accept, uses default input masking, and /privacy says so
 4  The only email is a password reset, which is transactional
 5  No recurring billing found
 6  Notes are private and nobody else can see them (my assumption: there is no sharing)
 7  /privacy and /terms both exist and are linked in the footer
 8  PostHog isn't loaded until the visitor clicks Accept

Fixes I can apply now: none. Needs a human: have a lawyer review /privacy and /terms.
Not legal advice. This is an automated check of 8 common traps, not a full legal review.
```

Nothing needs a code change. One thing to confirm by hand: masking in check 3 relies on PostHog's defaults, so make sure input masking is still on in your PostHog project settings.
