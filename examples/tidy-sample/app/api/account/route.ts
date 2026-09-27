import { NextResponse } from "next/server";
import { cookies } from "next/headers";
import { deleteUserByEmail, exportUserData } from "@/lib/users";

// Demo session: the signed-in user's email lives in an httpOnly cookie.
async function sessionEmail() {
  return (await cookies()).get("session_email")?.value;
}

// GET /api/account — download my data
export async function GET() {
  const email = await sessionEmail();
  if (!email) return NextResponse.json({ error: "Sign in first" }, { status: 401 });
  return NextResponse.json(await exportUserData(email), {
    headers: { "Content-Disposition": 'attachment; filename="my-tidy-notes-data.json"' },
  });
}

// DELETE /api/account — delete my account and data
export async function DELETE() {
  const email = await sessionEmail();
  if (!email) return NextResponse.json({ error: "Sign in first" }, { status: 401 });
  await deleteUserByEmail(email);
  (await cookies()).delete("session_email");
  return NextResponse.json({ deleted: true });
}
