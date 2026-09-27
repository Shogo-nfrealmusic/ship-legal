import { Link } from "react-router-dom";

const testimonials = [
  { name: "Jessica M.", text: "Lost 12 kg in 8 weeks with Coach Max!", stars: 5 },
  { name: "David K.", text: "Better than my $100/hour trainer.", stars: 5 },
  { name: "Priya S.", text: "The only fitness app that actually works.", stars: 5 },
];

export default function Landing() {
  return (
    <main>
      <img src="/hero.png" width={680} height={320} />
      <h1>Your AI-free personal trainer, 24/7</h1>
      <p>Trusted by 50,000+ athletes. Guaranteed results in 30 days.</p>
      <Link to="/signup"><button>Start free</button></Link>
      <section>
        {testimonials.map((t) => (
          <blockquote key={t.name}>
            {"★".repeat(t.stars)} “{t.text}” — {t.name}
          </blockquote>
        ))}
      </section>
      <footer className="muted">© 2026 ChatFit</footer>
    </main>
  );
}
