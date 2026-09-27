# Recipe: subscriptions (California Automatic Renewal Law)

Goal: before the person pays, they see the renewal terms right next to the button,
they actively agree, and they can cancel online without talking to anyone.

1. Disclosure in visual proximity to the subscribe button (same card, directly above
   or below, readable size and contrast; not in a tooltip or a linked page). Include:
   - the price and how often it is charged ("$12 charged every month"),
   - that it continues until they cancel,
   - how to cancel ("Cancel anytime in Settings → Billing"),
   - if there is a free trial: when it ends and what is charged then.
   Use the project's real price. If the price lives in Stripe only, read it from the
   code/env the page already uses, or use a clearly marked TODO; never guess a price.
2. Affirmative consent: an unchecked checkbox next to the disclosure
   ("I agree to the automatic renewal terms above"), and the subscribe button is
   disabled until it is checked. Also check it on the server if the request carries it.
3. Repeat the terms on the Stripe Checkout page:
   ```ts
   stripe.checkout.sessions.create({
     mode: "subscription",
     // ...
     custom_text: { submit: { message: "Your subscription renews automatically every month at $12 until you cancel. Cancel anytime in Settings → Billing." } },
   });
   ```
4. Online cancel path: Stripe Customer Portal.
   ```ts
   // app/api/billing-portal/route.ts
   const stripe = new Stripe(process.env.STRIPE_SECRET_KEY as string);
   const session = await stripe.billingPortal.sessions.create({ customer: user.stripeCustomerId, return_url: `${appUrl}/settings` });
   return NextResponse.redirect(session.url, 303);
   ```
   Add a visible "Manage or cancel subscription" button in account settings that posts
   to this route. If the app never stores the Stripe customer id, say so: it must be
   saved after checkout (webhook `checkout.session.completed` → `session.customer`).
   Do not build that webhook unless the project already has webhook handling; list it
   as a Human TODO otherwise.

Do not claim:
- that every renewal must be refunded (the "unconditional gift" rule in §17603 is about
  goods sent without consent);
- that the FTC "click-to-cancel" rule applies (it was vacated by the 8th Circuit on
  2025-07-08).
Human TODO: turn on cancellation in the Stripe Customer Portal settings; have a lawyer
check trial, price-change notice, and reminder rules for your plans.
