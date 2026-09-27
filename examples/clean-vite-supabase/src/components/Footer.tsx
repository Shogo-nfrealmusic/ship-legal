import { Link } from "react-router-dom";

export default function Footer() {
  return (
    <footer>
      <Link to="/privacy">Privacy Policy</Link> · <Link to="/terms">Terms of Service</Link> ·{" "}
      <Link to="/copyright">Copyright &amp; DMCA</Link>
    </footer>
  );
}
