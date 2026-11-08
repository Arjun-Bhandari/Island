import Image from "next/image";
import { CheckSquare, SquareTerminal, Trash2, Activity } from "lucide-react";
import { NotchPreview } from "./components/NotchPreview";
import { DownloadButton } from "./components/DownloadButton";

const INSTALL_COMMAND =
  "curl -fsSL https://raw.githubusercontent.com/Arjun-Bhandari/Island/main/scripts/install.sh | bash";
const DOWNLOAD_URL =
  "https://github.com/Arjun-Bhandari/Island/releases/latest/download/Island.zip";
const REPO_URL = "https://github.com/Arjun-Bhandari/Island";

const features = [
  {
    icon: CheckSquare,
    title: "Todo",
    body: "Capture what you need to do today without opening another app. Check things off right from the notch.",
  },
  {
    icon: SquareTerminal,
    title: "Script Runner",
    body: "Save the commands you run constantly. Run, stop, and watch long-running processes without touching Terminal.",
  },
  {
    icon: Trash2,
    title: "Dev Cleanup",
    body: "Finds node_modules, build caches, and DerivedData eating your disk — moves them to Trash, never deletes outright.",
  },
  {
    icon: Activity,
    title: "System Monitor",
    body: "CPU, memory, and storage at a glance, plus how much space you could reclaim right now.",
  },
];

export default function Home() {
  return (
    <div className="flex flex-1 flex-col items-center">
      {/* Nav */}
      <nav className="flex w-full max-w-5xl items-center justify-between px-6 py-6">
        <div className="flex items-center gap-2 text-sm font-semibold">
          <Image
            src="/icon.png"
            alt="Island"
            width={24}
            height={24}
            className="rounded-[7px]"
          />
          Island
        </div>
        <a
          href={REPO_URL}
          className="text-sm text-white/50 transition-colors hover:text-white"
        >
          GitHub
        </a>
      </nav>

      {/* Hero */}
      <section className="flex w-full max-w-3xl flex-col items-center px-6 pt-16 text-center sm:pt-24">
        <h1 className="text-4xl font-semibold tracking-tight sm:text-5xl">
          Your notch,
          <br />
          <span className="text-white/50">put to work.</span>
        </h1>
        <p className="mt-5 max-w-lg text-balance text-base text-white/50 sm:text-lg">
          Todo, script runner, dev cleanup, and a live system monitor —
          one hover away. Fully keyboard-driven, free, and yours.
        </p>

        <div className="mt-8 flex flex-col gap-3 sm:flex-row">
          <DownloadButton href={DOWNLOAD_URL}>
            Download for macOS
          </DownloadButton>
          <DownloadButton href={REPO_URL} primary={false}>
            View source
          </DownloadButton>
        </div>
        <p className="mt-4 text-sm font-medium text-white/55">
          macOS 14+ · or install from Terminal:
        </p>
        <code className="mt-2 max-w-full select-all overflow-x-auto whitespace-nowrap rounded-lg border border-white/10 bg-white/[0.04] px-3 py-2 font-mono text-xs text-white/70">
          {INSTALL_COMMAND}
        </code>
      </section>

      {/* Preview */}
      <section className="w-full px-6 pt-16 sm:pt-20">
        <div className="flex justify-center">
          <NotchPreview />
        </div>
      </section>

      {/* Features */}
      <section className="w-full max-w-5xl px-6 pt-24 sm:pt-32">
        <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
          {features.map((f) => (
            <div
              key={f.title}
              className="rounded-2xl border border-white/10 bg-white/[0.02] p-6"
            >
              <div className="flex h-10 w-10 items-center justify-center rounded-full bg-white/[0.06]">
                <f.icon size={18} strokeWidth={1.75} className="text-white" />
              </div>
              <h3 className="mt-4 text-base font-semibold">{f.title}</h3>
              <p className="mt-1.5 text-sm leading-relaxed text-white/50">
                {f.body}
              </p>
            </div>
          ))}
        </div>
      </section>

      {/* Keyboard-first callout */}
      <section className="w-full max-w-3xl px-6 pt-24 text-center sm:pt-32">
        <h2 className="text-2xl font-semibold tracking-tight">
          Never touch the mouse.
        </h2>
        <p className="mx-auto mt-3 max-w-md text-sm text-white/50">
          Every action — toggling the notch, jumping tabs, running a script —
          has a global shortcut. Default bindings included, every one
          fully customizable.
        </p>
        <div className="mt-8 flex flex-wrap justify-center gap-2 text-xs text-white/60">
          {[
            ["⌥Space", "Toggle notch"],
            ["⌥T", "Quick-add todo"],
            ["⌥S", "Open scripts"],
            ["⌥1–6", "Jump to tab"],
          ].map(([key, label]) => (
            <div
              key={key}
              className="flex items-center gap-2 rounded-full border border-white/10 bg-white/[0.03] px-3 py-1.5"
            >
              <kbd className="font-mono text-white">{key}</kbd>
              <span className="text-white/40">{label}</span>
            </div>
          ))}
        </div>
      </section>

      {/* Footer */}
      <footer className="mt-auto w-full px-6 py-12 text-center text-xs text-white/30">
        Built for a notch. Free, open source, and made for a few friends.
      </footer>
    </div>
  );
}
