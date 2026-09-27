# Recipe: neutral age screen (COPPA)

Goal: stop collecting data from users you would then know are under 13, without
teaching people which answer gets them in.

Do:
- Ask for birth month and year (or full date) at sign-up, before the account is created.
  Offer every year, including recent ones. No pre-selected adult year.
- Do not write "you must be 13+" next to the field, and do not use a
  "Yes, I am over 13" checkbox. Both hint at the "right" answer.
- Compute the age on the server, not only in the browser.
- Under 13: do not create the account and do not store the email, name, or birth date.
  Show a neutral message ("Sorry, we can't create an account for you right now.").
- Set a short-lived cookie (e.g. 24 h) so the form cannot simply be resubmitted
  with an older year right away.
- Store only what you need afterwards, e.g. `ageVerified13Plus: true`, not the birth date.
- OAuth-only sign-up (Google, GitHub...): put the same screen before the OAuth redirect,
  and check the cookie in the OAuth callback before creating the user.

Do not:
- Do not add identity or ID-document checks. That is not what this fix is.
- If the app looks directed to children (kid-focused content, cartoons, school ages),
  an age screen is NOT enough. COPPA then requires verifiable parental consent before
  collecting children's data. Put that in the Human TODO list instead of coding it.

Next.js App Router sketch (adapt names to the project):

```tsx
// in the sign-up form
const THIS_YEAR = new Date().getFullYear();
const YEARS = Array.from({ length: 101 }, (_, i) => THIS_YEAR - i);
<label>Birth month
  <select name="birthMonth" required defaultValue="">
    <option value="" disabled>Month</option>
    {Array.from({ length: 12 }, (_, i) => <option key={i} value={i + 1}>{i + 1}</option>)}
  </select>
</label>
<label>Birth year
  <select name="birthYear" required defaultValue="">
    <option value="" disabled>Year</option>
    {YEARS.map((y) => <option key={y} value={y}>{y}</option>)}
  </select>
</label>
```

```ts
// in the sign-up route handler, BEFORE creating the user
import { cookies } from "next/headers";
function ageFrom(year: number, month: number) {
  const now = new Date();
  let age = now.getFullYear() - year;
  if (now.getMonth() + 1 < month) age -= 1;
  return age;
}
const jar = await cookies();
if (jar.get("signup_blocked")) return NextResponse.json({ error: "Sorry, we can't create an account for you right now." }, { status: 403 });
const age = ageFrom(Number(birthYear), Number(birthMonth));
if (!Number.isFinite(age) || age < 13) {
  jar.set("signup_blocked", "1", { httpOnly: true, sameSite: "lax", maxAge: 60 * 60 * 24 });
  return NextResponse.json({ error: "Sorry, we can't create an account for you right now." }, { status: 403 });
}
// ...create the user; do not save birthYear/birthMonth
```
