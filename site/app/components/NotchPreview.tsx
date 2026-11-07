"use client";

import { useEffect, useState } from "react";
import { AnimatePresence, motion } from "motion/react";
import {
  House,
  CheckSquare,
  SquareTerminal,
  Activity,
  Trash2,
} from "lucide-react";

const tabs = [
  { icon: House, label: "Home" },
  { icon: CheckSquare, label: "Todo" },
  { icon: SquareTerminal, label: "Scripts" },
  { icon: Activity, label: "Monitor" },
  { icon: Trash2, label: "Cleanup" },
];

const CYCLE_MS = 3000;

export function NotchPreview() {
  const [active, setActive] = useState(0);
  const [paused, setPaused] = useState(false);

  useEffect(() => {
    if (paused) return;
    const id = setInterval(() => {
      setActive((i) => (i + 1) % tabs.length);
    }, CYCLE_MS);
    return () => clearInterval(id);
  }, [paused]);

  return (
    <motion.div
      initial={{ opacity: 0, y: 10 }}
      whileInView={{ opacity: 1, y: 0 }}
      viewport={{ once: true, margin: "-80px" }}
      transition={{ type: "spring", bounce: 0, duration: 0.7 }}
      onMouseEnter={() => setPaused(true)}
      onMouseLeave={() => setPaused(false)}
      className="w-full max-w-xl rounded-[28px] border border-white/10 bg-gradient-to-b from-white/[0.06] to-transparent p-3 shadow-2xl shadow-black/60"
    >
      <div className="rounded-[22px] bg-black p-4">
        <div className="flex items-center gap-1.5">
          {tabs.map((tab, i) => (
            <button
              key={tab.label}
              onClick={() => setActive(i)}
              className="relative flex items-center gap-1.5 rounded-full px-3 py-1.5 text-xs font-medium"
            >
              {active === i && (
                <motion.div
                  layoutId="tab-pill"
                  transition={{ type: "spring", bounce: 0, duration: 0.5 }}
                  className="absolute inset-0 rounded-full bg-white"
                />
              )}
              <span
                className={`relative z-10 flex items-center gap-1.5 ${
                  active === i ? "text-black" : "text-white/50"
                }`}
              >
                <tab.icon size={13} strokeWidth={2} />
                {active === i && <span>{tab.label}</span>}
              </span>
            </button>
          ))}
        </div>

        <div className="mt-4 h-[220px]">
          <AnimatePresence mode="wait">
            <motion.div
              key={active}
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              transition={{ duration: 0.2 }}
            >
              {active === 0 && <HomePane />}
              {active === 1 && <TodoPane />}
              {active === 2 && <ScriptsPane />}
              {active === 3 && <MonitorPane />}
              {active === 4 && <CleanupPane />}
            </motion.div>
          </AnimatePresence>
        </div>
      </div>
    </motion.div>
  );
}

function Card({ children }: { children: React.ReactNode }) {
  return <div className="rounded-xl bg-white/[0.05] p-3">{children}</div>;
}

function HomePane() {
  return (
    <div className="grid grid-cols-[1fr_1.3fr] gap-4">
      <div className="space-y-3">
        <div>
          <div className="text-sm font-semibold text-white">Saturday</div>
          <div className="text-xs text-white/40">7 November</div>
        </div>
        <Card>
          <div className="mb-2 flex items-center justify-between text-xs text-white/40">
            <span>Today</span>
            <span>1/3 done</span>
          </div>
          <div className="space-y-1.5 text-xs text-white/80">
            <div className="flex items-center gap-2">
              <span className="h-1 w-1 rounded-full bg-white/40" />
              Ship landing page
            </div>
            <div className="flex items-center gap-2">
              <span className="h-1 w-1 rounded-full bg-white/40" />
              Record demo
            </div>
          </div>
        </Card>
      </div>

      <div className="space-y-3">
        <Card>
          <div className="mb-2 text-xs font-semibold text-white/80">
            November 2026
          </div>
          <div className="grid grid-cols-7 gap-y-1 text-center text-[10px] text-white/30">
            {["S", "M", "T", "W", "T", "F", "S"].map((d, i) => (
              <span key={i}>{d}</span>
            ))}
            {Array.from({ length: 30 }, (_, i) => i + 1).map((day) => (
              <span
                key={day}
                className={`rounded-full py-0.5 text-[10px] ${
                  day === 7
                    ? "bg-white font-semibold text-black"
                    : "text-white/60"
                }`}
              >
                {day}
              </span>
            ))}
          </div>
        </Card>

        <div className="grid grid-cols-3 gap-2">
          {[
            { label: "CPU", value: "8%" },
            { label: "Memory", value: "11.7G" },
            { label: "Reclaim", value: "36.6G" },
          ].map((stat) => (
            <div
              key={stat.label}
              className="rounded-lg bg-white/[0.05] px-2 py-2 text-center"
            >
              <div className="text-xs font-semibold text-white">
                {stat.value}
              </div>
              <div className="text-[9px] text-white/40">{stat.label}</div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}

function TodoPane() {
  const items = [
    { text: "Ship landing page", done: false },
    { text: "Record demo video", done: false },
    { text: "Reply to friends' invites", done: true },
  ];
  return (
    <div className="space-y-3">
      <div className="flex items-center justify-between">
        <span className="text-sm font-semibold text-white">Today</span>
        <span className="text-xs text-white/40">1/3 done</span>
      </div>
      <div className="rounded-lg bg-white/[0.05] px-3 py-2 text-xs text-white/30">
        Add a todo for today…
      </div>
      <div className="space-y-2">
        {items.map((item) => (
          <div key={item.text} className="flex items-center gap-2 text-xs">
            <CheckSquare
              size={13}
              className={item.done ? "text-green-400" : "text-white/30"}
            />
            <span
              className={
                item.done ? "text-white/30 line-through" : "text-white/80"
              }
            >
              {item.text}
            </span>
          </div>
        ))}
      </div>
    </div>
  );
}

function ScriptsPane() {
  const scripts = [
    { name: "Dev server", cmd: "pnpm dev", running: true },
    { name: "Clean build", cmd: "rm -rf dist && build", running: false },
  ];
  return (
    <div className="space-y-3">
      <div className="flex items-center justify-between">
        <span className="text-sm font-semibold text-white">Scripts</span>
        <span className="text-xs text-white/40">⌥S</span>
      </div>
      {scripts.map((s) => (
        <div
          key={s.name}
          className="flex items-center gap-2 rounded-lg bg-white/[0.05] px-3 py-2"
        >
          <span
            className={`h-2 w-2 rounded-full ${
              s.running ? "bg-orange-400" : "bg-white/20"
            }`}
          />
          <div className="flex-1">
            <div className="text-xs font-medium text-white">{s.name}</div>
            <div className="font-mono text-[10px] text-white/40">
              {s.cmd}
            </div>
          </div>
        </div>
      ))}
    </div>
  );
}

function MonitorPane() {
  const stats = [
    { label: "CPU", value: "8%", pct: 8 },
    { label: "Memory (RAM)", value: "11.7 / 16 GB", pct: 73 },
    { label: "Storage", value: "253 / 460 GB", pct: 55 },
  ];
  return (
    <div className="space-y-3">
      <span className="text-sm font-semibold text-white">System</span>
      {stats.map((s) => (
        <div key={s.label} className="space-y-1">
          <div className="flex justify-between text-xs">
            <span className="text-white/70">{s.label}</span>
            <span className="font-mono text-white/40">{s.value}</span>
          </div>
          <div className="h-1 rounded-full bg-white/10">
            <div
              className="h-1 rounded-full bg-white/60"
              style={{ width: `${s.pct}%` }}
            />
          </div>
        </div>
      ))}
    </div>
  );
}

function CleanupPane() {
  const findings = [
    { kind: "node_modules", size: "1.2 GB" },
    { kind: "Xcode DerivedData", size: "8.4 GB" },
    { kind: ".next cache", size: "640 MB" },
  ];
  return (
    <div className="space-y-3">
      <div className="flex items-center justify-between">
        <span className="text-sm font-semibold text-white">Cleanup</span>
        <span className="text-xs text-orange-400">10.2 GB reclaimable</span>
      </div>
      {findings.map((f) => (
        <div
          key={f.kind}
          className="flex items-center justify-between rounded-lg bg-white/[0.05] px-3 py-2 text-xs"
        >
          <span className="text-white/80">{f.kind}</span>
          <span className="font-mono text-white/40">{f.size}</span>
        </div>
      ))}
    </div>
  );
}
