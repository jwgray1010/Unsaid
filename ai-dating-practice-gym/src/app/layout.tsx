import type { Metadata } from "next";
import { Geist, Geist_Mono } from "next/font/google";
import Link from "next/link";
import "./globals.css";

const geistSans = Geist({
  variable: "--font-geist-sans",
  subsets: ["latin"],
});

const geistMono = Geist_Mono({
  variable: "--font-geist-mono",
  subsets: ["latin"],
});

export const metadata: Metadata = {
  title: "AI Dating Practice Gym",
  description: "Practice realistic dates with AI personas and actionable coaching.",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body className={`${geistSans.variable} ${geistMono.variable} bg-background text-foreground antialiased`}>
        <div className="flex min-h-screen flex-col">
          <header className="border-b border-zinc-200 bg-white/80 backdrop-blur">
            <div className="mx-auto flex w-full max-w-5xl items-center justify-between px-4 py-3">
              <Link href="/" className="text-sm font-semibold tracking-tight text-zinc-900">
                AI Dating Practice Gym
              </Link>
              <nav className="flex items-center gap-2 text-sm">
                <Link className="rounded-lg px-3 py-1.5 text-zinc-700 hover:bg-zinc-100" href="/app">
                  Dashboard
                </Link>
                <Link className="rounded-lg px-3 py-1.5 text-zinc-700 hover:bg-zinc-100" href="/login">
                  Login
                </Link>
              </nav>
            </div>
          </header>

          <main className="mx-auto w-full max-w-5xl flex-1 px-4 py-8">{children}</main>

          <footer className="border-t border-zinc-200 bg-white px-4 py-4">
            <div className="mx-auto flex w-full max-w-5xl flex-col gap-1 text-xs text-zinc-500 sm:flex-row sm:justify-between">
              <p>Training tool, not therapy. Not for emergencies.</p>
              <p>For urgent crisis support in the U.S., call or text 988.</p>
            </div>
          </footer>
        </div>
      </body>
    </html>
  );
}
