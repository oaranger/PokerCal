import type { Metadata } from "next";
import { DM_Mono, Manrope } from "next/font/google";
import "./globals.css";

const manrope = Manrope({ variable: "--font-sans", subsets: ["latin"] });
const dmMono = DM_Mono({ variable: "--font-mono", subsets: ["latin"], weight: ["400", "500"] });

export const metadata: Metadata = {
  metadataBase: new URL("https://pokercal.bin-huy.chatgpt.site"),
  title: "PokerCal — Settle the table",
  description: "Balance poker buy-ins, cash-outs, and shared food expenses in seconds.",
  icons: { icon: "/favicon.svg", shortcut: "/favicon.svg" },
  openGraph: {
    title: "PokerCal — Everyone leaves square",
    description: "A simple, zero-sum poker night settlement calculator.",
    images: ["/og.png"],
  },
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return <html lang="en"><body className={`${manrope.variable} ${dmMono.variable}`}>{children}</body></html>;
}
