# Island — landing page

The marketing site for [Island](../README.md), a notch-based productivity app for macOS. Dark, Apple-style design with spring-based motion.

Live at `island.<your-domain>` (deployed on Vercel).

## Stack

- [Next.js](https://nextjs.org) (App Router)
- [Tailwind CSS](https://tailwindcss.com)
- [Motion](https://motion.dev) (Framer Motion) for the spring-based reveal and tab animations
- [lucide-react](https://lucide.dev) for icons

## What's on the page

- **Hero** — headline, download button (links to the latest GitHub release's `Island.zip`), "View source" link
- **Notch preview** — a mock of the real app's notch UI that auto-cycles through all five tabs (Home, Todo, Scripts, Monitor, Cleanup) every 3 seconds, pauses on hover, and only animates in once it scrolls into view (no animation on initial page load)
- **Feature grid** — the four modules, each with its own icon
- **Keyboard-shortcuts callout** — default bindings, since the app is built to be used without a mouse
- Favicon/app icon shared with the macOS app (`app/icon.png`, copied from `../Resources/icon_1024.png`)

## Development

```bash
npm install
npm run dev
```

Open [http://localhost:3000](http://localhost:3000).

```bash
npm run build   # production build — run this before deploying to catch errors
```

## Updating the download link

`app/page.tsx` points `DOWNLOAD_URL` at:

```
https://github.com/Arjun-Bhandari/Island/releases/latest/download/Island.zip
```

It never needs editing. `scripts/build-app.sh` writes both `dist/Island-<version>.zip` and an unversioned `dist/Island.zip`, and the Release workflow (`.github/workflows/release.yml`) attaches both to every release it publishes. GitHub's `/releases/latest/` alias resolves to the newest release that isn't marked "Pre-release".

## Deploying

Deployed on [Vercel](https://vercel.com). Since this app lives in a subfolder of the `Island` repo, **set the project's Root Directory to `site`** when importing — otherwise Vercel will try to build from the repo root and fail (there's a Swift package there, not a Next.js app).

1. [vercel.com/new](https://vercel.com/new) → import the `Island` repo
2. Root Directory: `site`
3. Framework preset: Next.js (auto-detected)
4. Deploy

### Custom domain

In the Vercel project's Settings → Domains, add your subdomain (e.g. `island.yourdomain.com`). At your DNS provider, add a **CNAME** record:

| Name | Type | Value |
|---|---|---|
| `island` | CNAME | `cname.vercel-dns.com` |

(Use a CNAME, not an A record — the `76.76.21.21` A record is only for apex/root domains that can't use CNAME.)
