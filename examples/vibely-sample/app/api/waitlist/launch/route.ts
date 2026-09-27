import { NextResponse } from "next/server";
import { Resend } from "resend";
import { db } from "@/lib/db";
import { launchAnnouncementEmail } from "@/emails/launch-announcement";

// POST /api/waitlist/launch  — sends the launch announcement to everyone on the waitlist.
export async function POST() {
  const resend = new Resend(process.env.RESEND_API_KEY);
  const { subject, html } = launchAnnouncementEmail({
    appUrl: process.env.NEXT_PUBLIC_APP_URL ?? "http://localhost:3000",
  });

  const emails = db.waitlistEmails();
  const { error } = await resend.batch.send(
    emails.map((to) => ({
      from: "Vibely <hello@vibely.app>",
      to,
      subject,
      html,
    })),
  );
  if (error) return NextResponse.json({ error: error.message }, { status: 500 });
  return NextResponse.json({ sent: emails.length });
}
