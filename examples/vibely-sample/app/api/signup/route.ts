import { NextResponse } from "next/server";
import { db, hashPassword } from "@/lib/db";

export async function POST(req: Request) {
  const { name, handle, email, password } = await req.json();
  if (!email || !password || !handle) {
    return NextResponse.json({ error: "Missing fields" }, { status: 400 });
  }
  const user = db.createUser({
    name,
    handle,
    email,
    passwordHash: await hashPassword(password),
  });
  return NextResponse.json({ id: user.id });
}
