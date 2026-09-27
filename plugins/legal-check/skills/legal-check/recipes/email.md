# Recipe: commercial email (CAN-SPAM) — unsubscribe + postal address

First decide what each email is.
- Commercial: promotes a product or service (launch announcements, newsletters,
  promo codes, "we're live", re-engagement). Needs this fix.
- Transactional: completes something the user started (password reset, receipt,
  login code, security notice). Opt-out and address rules don't apply to these. Leave them.

Fix for every commercial email:
1. Footer with a working unsubscribe link and a physical postal address.
   Never invent an address. Use a clearly marked placeholder that the human must fill:
   ```ts
   // lib/company.ts
   // TODO(legal-check): replace with your real postal address (street address, or a
   // registered P.O. box / private mailbox). CAN-SPAM requires a valid physical postal address.
   export const COMPANY_POSTAL_ADDRESS = process.env.COMPANY_POSTAL_ADDRESS ?? "TODO: your postal address";
   ```
   Footer HTML: `<p style="font-size:12px;color:#777">You're getting this because you joined the X waitlist.
   <a href="${unsubscribeUrl}">Unsubscribe</a> · ${COMPANY_POSTAL_ADDRESS}</p>`
2. Unsubscribe link carries a signed token, so nobody can unsubscribe someone else:
   ```ts
   // lib/unsubscribe.ts
   import { createHmac, timingSafeEqual } from "node:crypto";
   const secret = () => {
     const s = process.env.UNSUBSCRIBE_SECRET;
     if (!s) throw new Error("UNSUBSCRIBE_SECRET is not set");
     return s;
   };
   export const unsubscribeToken = (email: string) =>
     createHmac("sha256", secret()).update(email.toLowerCase()).digest("hex");
   export const verifyUnsubscribeToken = (email: string, token: string) => {
     const a = Buffer.from(unsubscribeToken(email)); const b = Buffer.from(token);
     return a.length === b.length && timingSafeEqual(a, b);
   };
   export const unsubscribeUrl = (appUrl: string, email: string) =>
     `${appUrl}/api/unsubscribe?email=${encodeURIComponent(email)}&token=${unsubscribeToken(email)}`;
   ```
3. Handler route: GET shows/does the unsubscribe; POST supports one-click
   (`List-Unsubscribe-Post`). Both mark the address as unsubscribed in the app's store,
   no login required.
4. Sending code: skip unsubscribed addresses, and add headers
   `List-Unsubscribe: <https://.../api/unsubscribe?...>` and
   `List-Unsubscribe-Post: List-Unsubscribe=One-Click` (Resend: `headers: {...}`).
   The unsubscribe URL is per recipient, so build the HTML per recipient.
5. Store: add an `unsubscribed` set/column next to where the list lives. If the project
   has a real database, follow its schema style and say a migration is needed; do not
   run migrations yourself.

Rules to state in the report: opt-outs must be honored within 10 business days, and the
unsubscribe link must keep working for at least 30 days after the email is sent.
Human TODO: set `UNSUBSCRIBE_SECRET` and `COMPANY_POSTAL_ADDRESS` in the hosting env.
