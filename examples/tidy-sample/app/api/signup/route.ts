import { NextResponse } from "next/server";
import { cookies } from "next/headers";
import { createUser } from "@/lib/users";

function ageFrom(year: number, month: number): number {
  const now = new Date();
  let age = now.getFullYear() - year;
  if (now.getMonth() + 1 < month) age -= 1;
  return age;
}

export async function POST(req: Request) {
  const { email, password, birthYear, birthMonth } = await req.json();
  const age = ageFrom(Number(birthYear), Number(birthMonth));

  if (!Number.isFinite(age) || age < 13) {
    // Under 13: do not create an account and do not store the email or birth date.
    // A session cookie stops the form from being retried with a different year.
    (await cookies()).set("signup_blocked", "1", { httpOnly: true, maxAge: 60 * 60 * 24 });
    return NextResponse.json({ message: "Sorry, we can't create an account for you." }, { status: 403 });
  }
  if ((await cookies()).get("signup_blocked")) {
    return NextResponse.json({ message: "Sorry, we can't create an account for you." }, { status: 403 });
  }

  // Only a boolean is kept, not the birth date.
  await createUser({ email, password, ageVerified13Plus: true });
  return NextResponse.json({ message: "Check your inbox to confirm your email." });
}
