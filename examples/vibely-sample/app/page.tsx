import Link from "next/link";

export default function Home() {
  return (
    <main>
      <h1 style={{ fontSize: 48, fontWeight: 800 }}>What&apos;s your vibe today?</h1>
      <p>Post one vibe a day. Photo, song, three words. See your friends&apos; vibes.</p>
      <p>
        <Link className="btn" href="/signup">Get started — it&apos;s free</Link>{" "}
        <Link href="/pricing">Pricing</Link>
      </p>
      <footer>© 2026 Vibely. Made with good vibes.</footer>
    </main>
  );
}
