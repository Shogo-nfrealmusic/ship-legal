import { Link } from "react-router-dom";

export default function Home() {
  return (
    <main>
      <img src="/runner.jpg" alt="A runner on a coastal trail at sunrise" width={680} height={320} />
      <h1>Log every run. Share the good ones.</h1>
      <p>Free running journal with a community feed.</p>
      <Link to="/signup">Create an account</Link> or continue with Google on the next page.
    </main>
  );
}
