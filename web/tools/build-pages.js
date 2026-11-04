#!/usr/bin/env node
/* Generates every site page from one shared layout. Run: npm run build
   SITE_URL sets canonical/OG/sitemap URLs (default: the domain already used by this repo's metadata). */
const fs = require('fs'), path = require('path');
const root = path.resolve(__dirname, '..');
const SITE = (process.env.SITE_URL || 'https://animatto-demo.vercel.app').replace(/\/$/, '');
const GH = 'https://github.com/sharmao07/Animatto';
const NAV = [['product', 'Product'], ['features', 'Features'], ['aquarium', 'Aquarium'], ['ambient-worlds', 'Ambient Worlds'], ['creator-studio', 'Creator Studio'], ['productivity', 'Productivity'], ['pricing', 'Pricing'], ['faq', 'FAQ']];
const FOOT = [['Explore', [['product', 'Product'], ['features', 'Features'], ['aquarium', 'Aquarium'], ['ambient-worlds', 'Ambient Worlds'], ['creator-studio', 'Creator Studio'], ['productivity', 'Productivity']]],
  ['Get it', [['download', 'Download'], ['pricing', 'Pricing'], ['faq', 'FAQ']]],
  ['Trust', [['privacy', 'Privacy'], ['licensing', 'Licensing'], ['support', 'Support']]]];
const chips = (id, label) => `<div class="chips" id="${id}" role="group" aria-label="${label}"></div>`;
const crumb = t => `<p class="crumb"><a href="/">Home</a> / ${t}</p>`;
const head = (eye, h, p, t) => `<div class="wrap ph">${crumb(t)}<p class="eye">${eye}</p><h1 style="font-size:clamp(36px,6vw,64px)">${h}</h1>${p ? `<p class="sub">${p}</p>` : ''}</div>`;
const sec = (inner, cls = '') => `<section class="${cls}"><div class="wrap">${inner}</div></section>`;
const note = t => `<p class="note">${t}</p>`;
const demoNote = 'This is a website preview built with original Animatto artwork. It is not the macOS app.';

const P = {};
P.index = ['Animatto — a tiny world, living on your Mac', 'Animatto is a native macOS desktop companion app with a hand-crafted cat, a desktop aquarium, ambient worlds and creator tools. Open source under Apache-2.0.',
`<div class="wrap hero"><p class="eye">A native macOS app</p><h1>Your desktop deserves a little <em>life.</em></h1>
<p class="sub">Meet your new desktop companions. They wander, play, react, swim and turn your Mac into a living environment.</p>
<a class="btn p" href="/download">Download for Mac</a> <a class="btn" href="/product">Explore Animatto</a>
<div class="desk" data-demo="hero" role="img" aria-label="Illustration of a Mac desktop with the Animatto cat walking on a window and an aquarium widget"><div class="mbar"><img src="assets/app_icon.png" alt=""><b>Animatto</b><span>Library</span><span>Workshop</span></div>
<div class="win"><i></i><i></i><i></i><b></b><b></b><b></b></div><img class="cat" alt="" data-cat><div class="dw"><canvas aria-hidden="true"></canvas></div></div>
<p class="cap">Illustration using the real Animatto cat and aquarium sprites. It is a website composition, not a screenshot of the running app.</p></div>
${sec(`<div class="two"><div><p class="eye">What it is</p><h2>Not just another desktop pet.</h2></div><ul class="list">
<li><b>Desktop companions</b>Physics-driven characters that walk, run, jump and fall on your real desktop. <a href="/features">Features</a></li>
<li><b>Desktop aquarium</b>Four original species in a transparent desktop window. <a href="/aquarium">Try it</a></li>
<li><b>Ambient Worlds</b>Rain, snow, fog, sunlight and leaves that companions react to. <a href="/ambient-worlds">Try it</a></li>
<li><b>Creator Studio</b>On-device Magic Eraser, AI sprite generation and your own imports. <a href="/creator-studio">Explore</a></li>
<li><b>Personality &amp; focus</b>Ten archetypes and a focus timer. <a href="/productivity">Try the timer</a></li></ul></div>`)}
${sec(`<p class="eye">Open core</p><h2>Free is genuinely useful.</h2><p class="sub">The core app is Apache-2.0 and stays free. <a href="/pricing">See pricing</a> · <a href="${GH}" rel="noopener">GitHub</a></p>`)}`];

P.product = ['Product', 'What Animatto is and how it works.', head('Product', 'A living desktop for your Mac.', 'Animatto is a native Swift, SwiftUI and AppKit application that gives your Mac desktop companions and environments.', 'Product') +
sec(`<dl><dt>Platform</dt><dd>macOS 14.6 or later, Apple Silicon and Intel. Mac only.</dd><dt>How it works</dt><dd>Companions are borderless transparent windows driven by a physics loop. They collide with surfaces, walk on application windows and can walk upside down along the menu bar.</dd><dt>Ambient layer</dt><dd>Weather particles render in a separate click-through overlay, so your clicks reach the apps beneath.</dd><dt>Control</dt><dd>A menu bar dashboard pauses, mutes and switches companions without opening the main window.</dd><dt>What makes it different</dt><dd>An open-source core, original hand-crafted sprites, personalities with needs and local memory, and an on-device Magic Eraser.</dd></dl>`)];

P.features = ['Features', 'Everything Animatto does today, based on the repository.', head('Features', 'What is in the app.', '', 'Features') + sec(`<dl>
<dt>Companions</dt><dd>Roaming, walking, running, jumping, falling, gravity, surface collision, window traversal, menu bar walking, drag and fling, multiple companions.</dd>
<dt>Personality</dt><dd>Ten archetypes with needs (energy, happiness, curiosity, boredom), contextual dialogue, quiet mode and anti-spam behaviour. <a href="/productivity#personality">Preview archetypes</a></dd>
<dt>Memory and social</dt><dd>Local memory of interactions and companion-to-companion encounters. Stored on your Mac.</dd>
<dt>Aquarium</dt><dd>Four original species, schooling, feeding, glass taps, bubbles and plants, themes and resizable windows. <a href="/aquarium">Try it</a></dd>
<dt>Ambient Worlds</dt><dd>Rain, snow, fog, sunlight beams, wind dust, falling leaves, cherry blossom petals, fireflies, rising steam and ocean waves. Eight built-in presets (Rainy Day, Enchanted Forest, Winter Calm, Sunset, Cosmic Dream, Sakura Garden, Cozy Café, Ocean), custom presets, <code>.animattopack</code> export and import, Open-Meteo weather sync, Inverse Weather Mode and a four-rarity collectible minigame.</dd>
<dt>Creator Studio</dt><dd>Magic Eraser (Apple Vision, on-device), AI sprite generation, community browser and imports. <a href="/creator-studio">Details</a></dd>
<dt>Productivity</dt><dd>Focus timers (5, 15, 30, 60 minutes) and Pomodoro (25/5, 50/10). <a href="/productivity">Try it</a></dd>
<dt>Audio</dt><dd>Footsteps, purring and aquarium sounds with master mute.</dd>
<dt>Integrations</dt><dd>Discord Rich Presence, Spotify and Apple Music status, GitHub Releases update checks. Privacy Shield stops background monitors instantly.</dd>
<dt>Accessibility &amp; Languages</dt><dd>Reduced Motion support and ambient atmosphere localization across 11 languages: English, Hindi, Japanese, Korean, Simplified and Traditional Chinese, Spanish, French, German, Italian, and Brazilian Portuguese.</dd></dl>`)];

P.aquarium = ['Aquarium', 'Try the Animatto aquarium in your browser: four species, water themes, feeding and glass taps.', head('Aquarium', 'A tank on your desktop.', 'Four original species in a transparent desktop window. Try the web preview.', 'Aquarium') + sec(`${chips('aq-themes', 'Water theme')}${chips('aq-sizes', 'Window size')}
<div class="stage a" id="aq-stage" data-demo="aquarium"><canvas aria-label="Aquarium preview. Move the pointer to attract fish and click the glass."></canvas></div>
<div class="ctl"><button class="btn p s" data-feed>Drop food</button><span class="cap" role="status" aria-live="polite" data-say>Move the pointer over the tank, or tap the glass.</span></div>
<p class="cap">${demoNote} Pip avoids the cursor, Finny is curious, Glow schools and Barnaby stays on the floor.</p>
<div class="sp"><div><b>Finny</b>Golden Sunfin</div><div><b>Pip</b>Spotted Pygmy Puffer</div><div><b>Glow</b>Neon Ghost Tetra</div><div><b>Barnaby</b>Mossy Hermit Crab</div></div>`)];

P['ambient-worlds'] = ['Ambient Worlds', 'Preview Animatto ambient atmospheres: rain, snow, sunset, sakura and more.', head('Ambient Worlds', 'Change the weather on your Mac.', 'In the app, particles render in a click-through overlay and companions react to the atmosphere.', 'Ambient Worlds') + sec(`<div data-demo="ambient"><p class="cap">Scene</p><div data-presets class="chips" role="group" aria-label="Scene"></div><p class="cap">Particle quality</p><div data-quality class="chips" role="group" aria-label="Particle quality"></div>
<div class="stage" style="aspect-ratio:2.2"><canvas aria-label="Ambient scene preview"></canvas></div><p data-desc class="note" aria-live="polite"></p></div>
${note(demoNote + ' The interactive previews here showcase Animatto’s eight built-in desktop atmospheric presets: Rainy Day, Enchanted Forest, Winter Calm, Sunset, Cosmic Dream, Sakura Garden, Cozy Café, and Ocean.')}`)];

P['creator-studio'] = ['Creator Studio', 'Explore Animatto companion customisation, Magic Eraser, AI sprite generation and imports.', head('Creator Studio', 'Make it yours.', '', 'Creator Studio') + sec(`<div class="two"><div data-demo="studio"><h3>Customisation preview</h3>
<div class="ctl"><label for="st-size">Size</label><input id="st-size" type="range" min="64" max="240" value="140"><label for="st-bg">Backdrop</label><select id="st-bg"><option value="#2c3a68">Dusk</option><option value="#56677d">Rain</option><option value="#a9c3dd">Snow</option><option value="#3a2a22">Café</option></select></div>
<p class="cap">Animation state</p><div class="chips" data-states role="group" aria-label="Animation state"></div><p class="cap">Personality</p><div class="chips" data-pers role="group" aria-label="Personality"></div>
<div class="stage" data-stage style="aspect-ratio:1.8;display:grid;place-items:center;background:#2c3a68"><img alt="Animatto cat preview" data-cat></div><p class="quote" data-quote aria-live="polite"></p>
<p class="cap">${demoNote} Size, backdrop, animation state and personality here are previews of options in the app.</p></div>
<dl style="grid-template-columns:1fr"><dt>Magic Eraser</dt><dd>Removes backgrounds on your Mac with Apple’s Vision framework, with no cloud upload. Only available in the macOS app.</dd><dt>AI Sprite Generator</dt><dd>Uses a configured image-generation provider, so it needs internet and a provider may have limits or costs.</dd><dt>Community browser</dt><dd>Browse and download community packs with creator attribution.</dd><dt>Imports</dt><dd>Your own PNG, GIF, WebP and compatible Shimeji-style packs. Respect each pack’s license.</dd></dl></div>`)];

P.productivity = ['Productivity', 'Try the Animatto focus timer and preview all ten personality archetypes.', head('Productivity', 'A companion that keeps you company.', 'Companions rest while you focus and celebrate your breaks.', 'Productivity') + sec(`<div class="two" data-demo="timer"><div><div data-presets class="chips" role="group" aria-label="Timer presets"></div><div class="tm" data-time role="timer" aria-live="off">25:00</div><div class="ring"><i data-bar style="width:0"></i></div><p class="mut" data-status role="status" aria-live="polite"></p><button class="btn p" data-go>Start</button> <button class="btn" data-reset>Reset</button></div><div><img alt="Animatto cat reacting to the timer" style="width:180px;image-rendering:pixelated"></div></div>
<p class="cap">${demoNote}</p>`) + sec(`<div id="personality" data-demo="personality"><p class="eye">Personality Matrix</p><h2>Ten archetypes.</h2><div class="two"><div><div data-chips class="chips" role="group" aria-label="Archetype"></div><p data-summary class="mut"></p><p class="quote" data-quote aria-live="polite"></p></div><div><div data-bars></div><img alt="Cat showing the selected archetype’s typical behaviour" style="width:140px;image-rendering:pixelated"></div></div>${note('Trait values come from the website’s sample data and the cat state is an illustrative mapping. The real engine also uses needs and context.')}</div>`)];

P.pricing = ['Pricing', 'Animatto is free and open source. Premium is planned and not yet on sale.', head('Pricing', 'Free is genuinely useful.', 'The core app is Apache-2.0 and a Premium purchase never revokes it.', 'Pricing') + sec(`<table><thead><tr><th scope="col">&nbsp;</th><th scope="col">Free</th><th scope="col">Premium (planned)</th></tr></thead><tbody>
<tr><td>Companions, physics, personality, dialogue, local memory</td><td>Included</td><td>Included</td></tr>
<tr><td>Aquarium (four species), Ambient Worlds, imports, timers, privacy features</td><td>Included</td><td>Included</td></tr>
<tr><td>Pro Sound Studio, exclusive palettes, custom aquarium geometry</td><td>—</td><td>Planned, not available</td></tr>
<tr><td>Devices</td><td>n/a</td><td>Up to 3 Macs (planned)</td></tr>
<tr><td>License</td><td>Apache-2.0</td><td>Separate Premium terms</td></tr>
<tr><td><b>Price</b></td><td><b>$0</b></td><td><b>$9.99</b> one-time (target)</td></tr></tbody></table>
<button class="btn" disabled aria-disabled="true">Premium purchases aren’t open yet</button>
${note('Checkout is intentionally not connected to this page. It will open only after payment security, durable storage and seller verification are complete. Refund terms will be published before purchases open. Hosted cloud sync and hosted AI are not available.')}
<h3>Planned activation</h3><ol class="mut"><li>Pay through a hosted checkout.</li><li>The server confirms payment and issues a signed license key.</li><li>Enter the key in Animatto.</li><li>The app validates the signed entitlement.</li></ol>`)];

P.download = ['Download', 'Download the latest Animatto release for macOS from GitHub Releases.', head('Download', 'Get Animatto for Mac.', 'Requires macOS 14.6 or later. Apple Silicon and Intel.', 'Download') + sec(`<div class="two"><div class="rel" data-demo="release" aria-live="polite"><p class="note" style="margin-bottom:16px">Animatto is currently in active release preparation. Nightly prerelease builds are available below; official v1.x stable releases will be published directly to GitHub Releases.</p><p data-state>Checking GitHub for the latest release…</p><div data-out hidden><h3 data-tag></h3><p class="mut" data-date></p><ul class="list" data-assets></ul><h3 style="margin-top:20px">Release notes</h3><pre data-notes></pre></div><p style="margin-top:16px"><a class="btn p" data-fallback href="${GH}/releases">View GitHub Releases</a></p></div>
<div><h3>Install</h3><ol><li>Open the DMG and drag Animatto into Applications.</li><li>Open Animatto.</li><li>If macOS warns about an unidentified developer, Control-click the app, choose Open, then confirm.</li></ol><p class="mut">Some releases may be ad-hoc signed and not notarized. Never disable Gatekeeper globally. To check a download run <code>shasum -a 256 Animatto.dmg</code> and compare it with a checksum published on the release. If none is published, the page says so.</p></div></div>`)];

P.faq = ['FAQ', 'Answers about installing, compatibility, privacy, features and pricing for Animatto.', head('FAQ', 'Questions, answered.', '', 'FAQ') + sec(`<div style="max-width:760px">${[
['Is Animatto Mac only?', 'Yes. It is a native macOS app: macOS 14.6 or later, Apple Silicon and Intel.'],
['Does the aquarium need its own app window?', 'It runs in a transparent desktop window that you can move and resize.'],
['Why does macOS show a security warning?', 'Some releases are not notarized. Control-click the app, choose Open and confirm once.'],
['How do I update?', 'Animatto checks the GitHub Releases API for new versions, and you can always download from the Download page.'],
['Does it collect telemetry?', 'The repository states there are no analytics SDKs, ad trackers or background telemetry. See Privacy for optional network features.'],
['Does Magic Eraser upload images?', 'No. It uses Apple’s Vision framework on your Mac.'],
['Does it work offline?', 'Core companion features do. Weather sync, AI generation, Discord and update checks use the network.'],
['Is Premium available?', 'Not yet. See Pricing for what is planned.'],
['Can I use my own characters?', 'You can import packs you own. Respect their license; Animatto only bundles its original artwork.']
].map(([q, a]) => `<details><summary>${q}</summary><p>${a}</p></details>`).join('')}</div>`)];

P.privacy = ['Privacy', 'How Animatto and this website handle your data.', head('Privacy', 'Local first.', '', 'Privacy') + sec(`<dl><dt>The app</dt><dd>Companion memory and preferences are stored locally. The repository documents zero analytics SDKs, ad trackers or background telemetry.</dd><dt>On-device</dt><dd>Magic Eraser runs with Apple Vision. Nothing is uploaded.</dd><dt>Optional network use</dt><dd>Open-Meteo weather sync, AI sprite generation through a configured provider, GitHub Releases update checks. Discord Rich Presence talks to the local Discord socket, and Spotify and Apple Music status is read through AppleScript on your Mac.</dd><dt>Payments</dt><dd>Not live. When enabled, payment goes through an external hosted provider and license activation involves license data.</dd><dt>This website</dt><dd>No analytics, cookies, tracking pixels or forms. The Download page asks GitHub’s public API for release data from your browser, so GitHub sees that request.</dd></dl><p class="cap">This is a plain-language summary, not legal advice. See <a href="${GH}/blob/main/SECURITY.md" rel="noopener">SECURITY.md</a>.</p>`)];

P.licensing = ['Licensing', 'Animatto is Apache-2.0 open source. Asset and audio licensing information.', head('Licensing', 'Apache-2.0 at the core.', '', 'Licensing') + sec(`<dl><dt>Application</dt><dd>Apache License 2.0. <a href="${GH}/blob/main/LICENSE" rel="noopener">Read the license</a>.</dd><dt>Artwork</dt><dd>The cat and aquarium sprites are original Animatto artwork. Each folder under <code>sprites/</code> carries its own attribution and license file. See <a href="${GH}/blob/main/docs/ASSET_LICENSE_AUDIT.md" rel="noopener">the asset audit</a>.</dd><dt>Audio</dt><dd><a href="${GH}/blob/main/docs/AUDIO_LICENSES.md" rel="noopener">Audio licenses</a>.</dd><dt>Premium</dt><dd>Separately licensed modules and content follow their own terms and never revoke the Apache-2.0 core.</dd><dt>Trademarks</dt><dd>Mac and macOS are trademarks of Apple Inc. Animatto is not affiliated with Apple.</dd></dl>`)];

P.support = ['Support', 'Get help with Animatto: report bugs, request features and report security issues.', head('Support', 'Talk to the humans.', '', 'Support') + sec(`<dl><dt>Bugs and features</dt><dd><a href="${GH}/issues" rel="noopener">Open a GitHub issue</a></dd><dt>Installation help</dt><dd>Start with <a href="/download">Download</a> and <a href="/faq">FAQ</a>, then open an issue.</dd><dt>Security</dt><dd><a href="${GH}/blob/main/SECURITY.md" rel="noopener">Security policy</a></dd><dt>Contributing</dt><dd><a href="${GH}/blob/main/CONTRIBUTING.md" rel="noopener">Contribution guide</a></dd><dt>Premium and payments</dt><dd>Not live yet. No payment support channel exists to publish.</dd></dl>`)];

const layout = (slug, [title, desc, body]) => {
  const url = `${SITE}/${slug === 'index' ? '' : slug}`, full = slug === 'index' ? title : `${title} — Animatto`;
  return `<!DOCTYPE html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
<title>${full}</title><meta name="description" content="${desc}"><link rel="canonical" href="${url}">
<link rel="icon" type="image/png" href="/assets/favicon.png"><link rel="apple-touch-icon" href="/assets/apple-touch-icon.png">
<meta property="og:type" content="website"><meta property="og:site_name" content="Animatto"><meta property="og:title" content="${full}"><meta property="og:description" content="${desc}"><meta property="og:url" content="${url}"><meta property="og:image" content="${SITE}/assets/og-image.png">
<meta name="twitter:card" content="summary_large_image"><meta name="twitter:title" content="${full}"><meta name="twitter:description" content="${desc}"><meta name="twitter:image" content="${SITE}/assets/og-image.png">
<link rel="stylesheet" href="/css/site.css"></head><body>
<a class="skip" href="#main">Skip to content</a>
<header><div class="wrap"><a class="logo" href="/"><img src="/assets/app_icon.png" alt="" width="32" height="32">Animatto</a>
<button id="mb" class="btn s" aria-expanded="false" aria-controls="nv">Menu</button>
<nav id="nv" aria-label="Main">${NAV.map(([s, l]) => `<a href="/${s}"${s === slug ? ' aria-current="page"' : ''}>${l}</a>`).join('')}<a href="/download" class="btn p s"${slug === 'download' ? ' aria-current="page"' : ''}>Download</a></nav></div></header>
<main id="main">${body}</main>
<footer><div class="wrap"><div class="cols">${FOOT.map(([h, l]) => `<div><h2>${h}</h2>${l.map(([s, t]) => `<a href="/${s}">${t}</a>`).join('')}</div>`).join('')}<div><h2>Project</h2><a href="${GH}" rel="noopener">GitHub</a><a href="${GH}/releases" rel="noopener">Releases</a><a href="${GH}/blob/main/LICENSE" rel="noopener">Apache-2.0</a></div></div><p style="margin-top:24px">Animatto is open source. Mac and macOS are trademarks of Apple Inc.</p></div></footer>
<script type="module" src="/js/site.js"></script></body></html>
`;
};
const files = Object.entries(P);
for (const [slug, page] of files) fs.writeFileSync(path.join(root, slug === 'index' ? 'index.html' : `${slug}.html`), layout(slug, page));
const today = new Date().toISOString().slice(0, 10);
fs.writeFileSync(path.join(root, 'sitemap.xml'), `<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n${Object.keys(P).map(s => `  <url><loc>${SITE}/${s === 'index' ? '' : s}</loc><lastmod>${today}</lastmod></url>`).join('\n')}\n</urlset>\n`);
fs.writeFileSync(path.join(root, 'robots.txt'), `User-agent: *\nAllow: /\nDisallow: /api/\n\nSitemap: ${SITE}/sitemap.xml\n`);
console.log(`Built ${Object.keys(P).length} pages for ${SITE}`);
