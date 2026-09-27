import { NextResponse } from "next/server";
import Stripe from "stripe";

export async function POST() {
  const stripe = new Stripe(process.env.STRIPE_SECRET_KEY as string);
  const appUrl = process.env.NEXT_PUBLIC_APP_URL ?? "http://localhost:3000";

  const session = await stripe.checkout.sessions.create({
    mode: "subscription",
    line_items: [{ price: process.env.STRIPE_PRICE_PRO, quantity: 1 }],
    success_url: `${appUrl}/settings/profile?upgraded=1`,
    cancel_url: `${appUrl}/pricing`,
  });

  return NextResponse.json({ url: session.url });
}
