"use client";

export default function Account() {
  async function remove() {
    if (!confirm("Delete your account and all your notes? This can't be undone.")) return;
    await fetch("/api/account", { method: "DELETE" });
    location.href = "/";
  }
  return (
    <main>
      <h1>Your account</h1>
      <a href="/api/account">Download my data</a>
      <button type="button" onClick={remove}>Delete my account</button>
    </main>
  );
}
