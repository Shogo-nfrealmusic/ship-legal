import { notFound } from "next/navigation";
import { db } from "@/lib/db";

export default async function PublicProfile({ params }: { params: Promise<{ handle: string }> }) {
  const { handle } = await params;
  const user = db.findByHandle(handle);
  if (!user) notFound();

  return (
    <main>
      {user.avatarUrl && (
        <img src={user.avatarUrl} alt={`${user.name}'s profile picture`} width={128} height={128} style={{ borderRadius: "50%" }} />
      )}
      <h1>{user.name}</h1>
      <p>@{user.handle}</p>
    </main>
  );
}
