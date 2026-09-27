import { NextResponse } from "next/server";
import { Resend } from "resend";
import { passwordResetEmail } from "@/emails/password-reset";
import { findUserByEmail } from "@/lib/users";

export async function POST(req: Request) {
  const { email } = await req.json();
  const user = await findUserByEmail(email);
  if (user) {
    const resend = new Resend(process.env.RESEND_API_KEY);
    const { subject, html } = passwordResetEmail(`https://tidynotes.app/reset?t=${crypto.randomUUID()}`);
    await resend.emails.send({ from: "Tidy Notes <no-reply@tidynotes.app>", to: email, subject, html });
  }
  return NextResponse.json({ ok: true });
}
