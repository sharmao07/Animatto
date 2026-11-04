/* Validates the generated Animatto website: pages, internal links, assets, metadata, CSP safety, JS syntax. */
const fs = require('fs'), path = require('path'), { execSync } = require('child_process');
const web = path.resolve(__dirname, '..');
let failures = 0;
const ok = (c, m) => { if (c) console.log(`PASS: ${m}`); else { console.error(`FAIL: ${m}`); failures++; } };
const pages = ['index', 'product', 'features', 'aquarium', 'ambient-worlds', 'creator-studio', 'productivity', 'pricing', 'download', 'faq', 'privacy', 'licensing', 'support'];
const html = Object.fromEntries(pages.map(p => [p, fs.existsSync(path.join(web, p + '.html')) ? fs.readFileSync(path.join(web, p + '.html'), 'utf8') : '']));

for (const p of pages) {
  const h = html[p];
  ok(h.length > 500, `${p}.html exists`);
  ok(/<title>[^<]{5,}<\/title>/.test(h) && /name="description" content="[^"]{30,}/.test(h), `${p}: title and description`);
  ok(/rel="canonical" href="https?:\/\//.test(h) && /property="og:image"/.test(h) && /name="twitter:card"/.test(h), `${p}: canonical, Open Graph, Twitter`);
  ok((h.match(/<h1[ >]/g) || []).length === 1, `${p}: exactly one h1`);
  ok(!/\son[a-z]+="/i.test(h) && !/<script(?![^>]*src)/.test(h), `${p}: no inline handlers or inline scripts (CSP)`);
  ok(!/api\/checkout|sandbox/i.test(h), `${p}: no checkout or sandbox link`);
  for (const m of h.matchAll(/(?:href|src)="(\/[^"#]*)"/g)) {
    const raw = m[1].split('?')[0];
    const t = raw === '/' ? 'index.html' : raw.replace(/^\//, '');
    if (!(fs.existsSync(path.join(web, t)) || fs.existsSync(path.join(web, t + '.html')))) ok(false, `${p}: broken internal reference ${m[1]}`);
  }
  for (const m of h.matchAll(/<img[^>]*>/g)) ok(/\salt="/.test(m[0]), `${p}: image has alt`);
}
for (const f of ['js/site.js', 'js/aquarium.js', 'js/ambient.js', 'js/personality.js', 'js/timer.js', 'js/sprites.js']) {
  try { execSync(`node --check --input-type=module < ${path.join(web, f)}`, { shell: '/bin/bash' }); ok(true, `${f} syntax`); } catch (e) { ok(false, `${f} syntax`); }
}
for (const a of ['app_icon.png', 'favicon.png', 'apple-touch-icon.png', 'og-image.png']) ok(fs.existsSync(path.join(web, 'assets', a)), `assets/${a}`);
ok(fs.existsSync(path.join(web, 'favicon.ico')), 'favicon.ico exists in root');
const sm = fs.readFileSync(path.join(web, 'sitemap.xml'), 'utf8');
ok(pages.every(p => sm.includes(p === 'index' ? '/</loc>' : `/${p}</loc>`)), 'sitemap lists every page');
ok(/Sitemap:/.test(fs.readFileSync(path.join(web, 'robots.txt'), 'utf8')), 'robots.txt references sitemap');
const vj = JSON.parse(fs.readFileSync(path.join(web, 'vercel.json'), 'utf8'));
ok(vj.cleanUrls === true && Array.isArray(vj.headers), 'vercel.json cleanUrls and headers');
ok(!fs.existsSync(path.join(web, 'sprites', 'miku.png')), 'unlicensed third-party sprites absent');
for (const j of ['data/personalities.json', 'data/presets.json']) { try { ok(JSON.parse(fs.readFileSync(path.join(web, j))).length >= 6, `${j} parses`); } catch { ok(false, `${j} parses`); } }
for (const [d, n] of [['cat', 9], ['aquarium/sunfin', 5], ['aquarium/puffer', 5], ['aquarium/tetra', 5], ['aquarium/hermitcrab', 5]]) ok(fs.readdirSync(path.join(web, 'sprites', d)).length >= n, `sprites/${d} populated`);
console.log(failures ? `\n${failures} FAILURE(S)` : '\nAll website checks passed.');
process.exit(failures ? 1 : 0);
