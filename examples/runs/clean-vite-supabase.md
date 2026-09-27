# Clean control: Vite + Supabase

Prompt: `/legal-check`

## Turn 1

Duration 39 s · cost $0.54 at API list prices · 10 tool calls

```
legal-check · clean · vite-react + supabase
0 RISK (0 High) · 1 CHECK · 9 PASS · 14 N/A

CHECK  C1 Is the DMCA agent registered? (100 Example St / 555-0100 look like placeholders)
PASS   S1 Secrets · S2 Database (RLS on all tables) · P4 Fonts (self-hosted)
       P5 Policy & terms · P6 Deletion & export · K1 Neutral age screen (server-side)
       C2 Report & block · C4 AI disclosure · A1 Accessibility basics
N/A    S3 Admin · S4 Card data · S5 Login (Supabase Auth) · P1 Replay
       P2 Ad pixels · P3 Cookies (Plausible) · P7 Do Not Sell · K2 Age rating
       M1 Email · M2 SMS · M3 Claims · $1 Subscriptions · $2 Refunds · C3 Trademarks

Nothing to fix in code.

Human TODO
 [ ] Register a DMCA agent at dmca.copyright.gov ($6, renew every 3 years), then
     replace the address and phone on /copyright with the real details.
 [ ] Worth a look (bugs, not legal traps): "Download my data" exports every user's
     posts, not only yours (src/pages/Account.tsx:8). Blocked users show up again
     in the feed after a reload (src/pages/Feed.tsx:10).
 [ ] Have a lawyer review the privacy policy, terms, and DMCA page.

Not legal advice — an automated check of common traps, not a full legal review.
```
