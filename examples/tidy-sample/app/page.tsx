import Link from "next/link";

export default function Home() {
  return (
    <main>
      <h1>Tidy Notes</h1>
      <p>Your notes, private by default. Free forever.</p>
      <Link href="/signup">Create an account</Link>
    </main>
  );
}
