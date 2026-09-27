"use client";

import { useState } from "react";

export default function ProfileSettings() {
  const [avatar, setAvatar] = useState<string | null>(null);

  async function onFile(e: React.ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0];
    if (!file) return;
    const body = new FormData();
    body.append("file", file);
    const res = await fetch("/api/avatar", { method: "POST", body });
    const { url } = await res.json();
    setAvatar(url);
  }

  return (
    <main>
      <h1>Your profile</h1>
      {avatar && <img src={avatar} alt="Your profile picture" width={96} height={96} style={{ borderRadius: "50%" }} />}
      <label>
        Profile picture
        <input type="file" accept="image/*" onChange={onFile} />
      </label>
      <p>Your picture is shown on your public profile.</p>
    </main>
  );
}
