"use client";

import { motion } from "motion/react";

export function DownloadButton({
  href,
  children,
  primary = true,
}: {
  href: string;
  children: React.ReactNode;
  primary?: boolean;
}) {
  return (
    <motion.a
      href={href}
      whileTap={{ scale: 0.96 }}
      transition={{ type: "spring", damping: 1, stiffness: 500, mass: 0.3 }}
      className={
        primary
          ? "inline-flex h-12 items-center justify-center gap-2 rounded-full bg-white px-6 text-sm font-semibold text-black transition-colors hover:bg-white/90"
          : "inline-flex h-12 items-center justify-center gap-2 rounded-full border border-white/15 px-6 text-sm font-semibold text-white transition-colors hover:bg-white/[0.06]"
      }
    >
      {children}
    </motion.a>
  );
}
