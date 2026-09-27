import type { Metadata } from "next";
import Link from "next/link";
import { Inter } from "next/font/google";
import { ConsentBanner } from "@/components/ConsentBanner";

// next/font/google downloads the font at build time and serves it from this site,
// so visitors' browsers never contact Google.
const inter = Inter({ subsets: ["latin"] });

export const metadata: Metadata = { title: "Tidy Notes", description: "Private notes." };

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" className={inter.className}>
      <body>
        {children}
        <footer>
          <Link href="/privacy">Privacy Policy</Link> · <Link href="/terms">Terms of Service</Link> · <Link href="/account">Account</Link>
        </footer>
        <ConsentBanner />
      </body>
    </html>
  );
}
