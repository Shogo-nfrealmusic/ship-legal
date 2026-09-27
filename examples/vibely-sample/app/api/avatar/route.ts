import { NextResponse } from "next/server";
import { put } from "@vercel/blob";
import { currentUserId, db } from "@/lib/db";

export async function POST(req: Request) {
  const form = await req.formData();
  const file = form.get("file");
  if (!(file instanceof File)) {
    return NextResponse.json({ error: "No file" }, { status: 400 });
  }
  const blob = await put(`avatars/${currentUserId()}-${file.name}`, file, { access: "public" });
  db.update(currentUserId(), { avatarUrl: blob.url });
  return NextResponse.json({ url: blob.url });
}
