# Animatto Web

The official Animatto website: 13 static pages plus client-side interactive demos. No framework, no bundler, no runtime dependencies.

## Structure

| Path | Purpose |
|---|---|
| `tools/build-pages.js` | Generates every `*.html` page, `sitemap.xml` and `robots.txt` from one shared layout. **Edit page content here, then run `npm run build`.** |
| `css/site.css` | Shared design system (tokens, light/dark, components, reduced motion). |
| `js/site.js` | Mobile nav and loaders for each demo (`data-demo="…"` attributes). Also the creator preview and the GitHub release lookup. |
| `js/aquarium.js`, `ambient.js`, `personality.js`, `timer.js`, `sprites.js` | Demo engines. |
| `data/personalities.json`, `data/presets.json` | Demo data. |
| `sprites/` | Original Animatto cat and aquarium sprites (each folder has its own license and attribution). |
| `assets/` | App icon, favicons, Open Graph image. |
| `api/`, `lib/` | Payment, license and email serverless code (see below). **Not used by the pages.** |
| `test/` | `validate_web.js` (static checks), `test_backend.js` (API tests), `browser_check.py` (Playwright). |

Pages: Home, Product, Features, Aquarium, Ambient Worlds, Creator Studio, Productivity (focus timer and personality demo), Pricing, Download, FAQ, Privacy, Licensing, Support. `vercel.json` has `cleanUrls`, so `/aquarium` serves `aquarium.html`.

## Commands

```bash
npm run build   # regenerate pages, sitemap.xml, robots.txt
npm start       # http://localhost:3000 (note: python's server has no clean URLs; use /aquarium.html locally)
npm test        # static validation of all pages, links, metadata, CSP safety, JS syntax
node test/test_backend.js        # payment/license API tests
python3 test/browser_check.py    # needs `pip install playwright` and a Chromium; SHOTS=dir saves screenshots
```

## Configuration

- `SITE_URL` (build time) sets canonical, Open Graph and sitemap URLs. Default `https://animatto-demo.vercel.app`, the domain already present in this repo's earlier metadata. The payment code references `animatto.app`, so **confirm which domain you own and set `SITE_URL` before launch.**
- Payment variables (`DODO_PAYMENTS_API_KEY`, `DODO_PAYMENTS_WEBHOOK_SECRET`, `DODO_PAYMENTS_MODE`, `DODO_PAYMENTS_PRODUCT_ID`, `LICENSE_SIGNING_PRIVATE_KEY`, `RESEND_API_KEY`, `EMAIL_FROM`, `DATABASE_URL` / `POSTGRES_URL`) are read only by `api/` and `lib/`. They are never needed by the pages.

## Download page and GitHub Releases

`js/site.js` queries GitHub Releases API in the visitor's browser and displays release version, date, notes, and asset sizes. Only assets hosted on official GitHub hostnames are listed. A SHA-256 is shown only if GitHub provides an asset `digest` or the release notes contain a 64-character hash on the asset's line; otherwise the page says none is published. Pre-releases and nightly builds are accurately marked.

## Pricing and payments

The core app is 100% free under Apache-2.0. Optional paid tiers are described as planned: **Lifetime Pro ($3.99 USD)** and **Founder Supporter ($5.99 USD)**, both one-time payments with zero recurring subscriptions. The purchase button on `/pricing` is disabled and no page links to `/api/checkout`. Dodo Payments integration remains in test sandbox mode.

## Updating content and assets

Change copy in `tools/build-pages.js`, swap images in `assets/`, edit demo data in `data/`, then `npm run build && npm test`. Deploy the `web/` folder to Vercel.
