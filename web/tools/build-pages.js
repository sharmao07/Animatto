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
const demoNote = 'This preview uses the same artwork and the same two actions as the Mac app. The download itself is the GitHub Release.';
const appWindow = (open = 'library') => {
  const current = open === 'aquarium' ? 'aquarium' : open;
  const nav = (id, label) => `<button type="button" data-nav="${id}"${current === id ? ' aria-current="true"' : ''}>${label}${id === 'library' ? '<em data-roam hidden>1</em>' : ''}</button>`;
  const on = id => id === open || (open === 'aquarium' && id === 'stage');
  const hide = id => on(id) ? '' : ' hidden';
  return `<div class="appwin" data-demo="hero" data-open="${open}" aria-label="Animatto app preview">
<div class="aw-title" aria-hidden="true"><i></i><i></i><i></i><b>Animatto</b><span>File</span><span>Edit</span><span>View</span><span>Companions</span><span>Window</span><span>Help</span></div>
<div class="aw-body">
<aside class="aw-side">
<div class="aw-id"><img src="/assets/app_icon.png" alt=""><div><b>Animatto</b><small>v1.2.0</small></div></div>
<nav aria-label="App sections">
<p>Companions</p>${nav('library', 'Library')}
<p>Environments</p>${nav('aquarium', 'Aquarium Mode')}${nav('ambient', 'Ambient Worlds')}
<p>Studio</p>${nav('workshop', 'Workshop')}
<p>Tools</p>${nav('productivity', 'Productivity')}${nav('audio', 'Audio Console')}
<p>Preferences</p>${nav('settings', 'Settings')}
</nav>
<div class="aw-foot"><b>Offline &amp; Local First</b><small>Zero telemetry · 100% on-device</small></div>
</aside>
<div class="aw-content">
<section data-pane="library"${hide('library')}>
<header class="aw-h"><h2>Companions Library</h2><p>Manage, inspect, and launch roaming desktop companions</p></header>
<div class="aw-split">
<div>
<div class="aw-sub">Saved Companions <span>6</span></div>
<div class="aw-grid">
<button type="button" class="aw-card" data-pet data-state="sit" data-label="Mochi" aria-pressed="true"><img src="/sprites/cat/sit/sit_00.png" alt=""><span>Mochi</span></button>
<button type="button" class="aw-card" data-pet data-state="idle" data-label="idle" aria-pressed="false"><img src="/sprites/cat/idle/idle_00.png" alt=""><span>idle</span></button>
<button type="button" class="aw-card" data-pet data-state="walk" data-label="walk" aria-pressed="false"><img src="/sprites/cat/walk/walk_00.png" alt=""><span>walk</span></button>
<button type="button" class="aw-card" data-pet data-state="run" data-label="run" aria-pressed="false"><img src="/sprites/cat/run/run_00.png" alt=""><span>run</span></button>
<button type="button" class="aw-card" data-pet data-state="sleep" data-label="sleep" aria-pressed="false"><img src="/sprites/cat/sleep/sleep_00.png" alt=""><span>sleep</span></button>
<button type="button" class="aw-card" data-pet data-state="jump" data-label="jump" aria-pressed="false"><img src="/sprites/cat/jump/jump_00.png" alt=""><span>jump</span></button>
</div>
</div>
<aside class="aw-insp">
<div class="aw-name"><b data-name>Mochi</b><small>PNG</small></div>
<div class="aw-prev"><img alt="" data-preview src="/sprites/cat/sit/sit_00.png"></div>
<button type="button" class="aw-launch" data-launch>Launch onto Desktop</button>
<label class="aw-scale">Desktop Spawn Scale <b data-px>150 px</b><input type="range" min="80" max="220" value="150" data-scale aria-label="Desktop spawn scale"></label>
<small class="aw-hint">Initial rendered bounding box size</small>
</aside>
</div>
</section>
<section data-pane="stage"${hide('stage')}>
<header class="aw-h aw-stagebar">
<div><h2 data-stage-title>On your desktop</h2><p data-stage-copy>The companion walks on the window. Aquarium Mode only covers the widgets.</p></div>
<div class="aw-stageacts">
<button type="button" class="aw-back" data-back>Library</button>
<button type="button" data-dismiss hidden>Dismiss</button>
<button type="button" data-feed-mini hidden>Feed</button>
<button type="button" class="switch" data-aq role="switch" aria-checked="false" aria-label="Aquarium Mode"></button>
</div>
</header>
<div class="aw-desk">
<div class="win" aria-hidden="true"><i></i><i></i><i></i><b></b><b></b><b></b></div>
<img class="aw-cat" alt="" data-cat>
<div class="widgets">
<div class="tile sq clock"><span class="face"><span class="clockface" aria-hidden="true"></span><small>Clock</small></span><canvas aria-hidden="true"></canvas></div>
<div class="tile wide weather"><span class="face"><small>Moradabad</small><b>19°</b><em>Clear</em><span class="hours"><span>12AM<br>19°</span><span>1AM<br>19°</span><span>2AM<br>18°</span><span>3AM<br>17°</span></span></span><canvas aria-hidden="true"></canvas></div>
<div class="tile sq cal"><span class="face"><small>November</small><span class="days" aria-hidden="true"><i>S</i><i>M</i><i>T</i><i>W</i><i>T</i><i>F</i><i>S</i><i>1</i><i>2</i><i>3</i><i>4</i><i>5</i><i>6</i><i class="today">7</i><i>8</i><i>9</i><i>10</i><i>11</i><i>12</i><i>13</i><i>14</i><i>15</i><i>16</i><i>17</i><i>18</i><i>19</i><i>20</i><i>21</i><i>22</i><i>23</i><i>24</i><i>25</i><i>26</i><i>27</i><i>28</i><i>29</i><i>30</i></span></span><canvas aria-hidden="true"></canvas></div>
<div class="tile wide bat"><span class="face"><span class="rings"><span class="ringc" style="--p:33%"><span>33%</span></span><span class="ringc" style="--p:85%"><span>85%</span></span></span><small>Battery</small></span><canvas aria-hidden="true"></canvas></div>
</div>
</div>
</section>
<section data-pane="ambient"${hide('ambient')}><header class="aw-h"><h2>Ambient Worlds</h2><p>A click-through atmosphere. Your companion stays a companion.</p></header><div data-presets class="chips" role="group" aria-label="Scene"></div><div class="aw-canvas"><canvas aria-label="Ambient scene preview"></canvas></div><p data-desc class="aw-hint" aria-live="polite"></p><div data-quality hidden></div></section>
<section data-pane="workshop"${hide('workshop')}><header class="aw-h"><h2>Workshop</h2><p>Personality changes how Mochi rests, walks, and greets you.</p></header><div class="aw-split"><div><div data-chips class="chips" role="group" aria-label="Archetype"></div><p data-summary></p><p data-quote class="aw-quote"></p><div data-bars></div></div><div class="aw-prev"><img alt="" src="/sprites/cat/idle/idle_00.png"></div></div></section>
<section data-pane="productivity"${hide('productivity')}><header class="aw-h"><h2>Productivity</h2><p>Mochi rests while you focus and celebrates the break.</p></header><div data-presets class="chips" role="group" aria-label="Timer length"></div><div class="aw-timer"><img alt="" src="/sprites/cat/idle/idle_00.png"><div><b data-time>25:00</b><p data-status></p><span class="ring"><i data-bar></i></span><div class="aw-stageacts"><button type="button" class="aw-launch" data-go>Start</button><button type="button" data-reset>Reset</button></div></div></div></section>
<section data-pane="audio"${hide('audio')}><header class="aw-h"><h2>Audio Console</h2><p>Footsteps, purring, and the tank. This preview does not play sound.</p></header><div class="aw-row"><span data-mute-label>Sound On</span><button type="button" class="switch" data-mute role="switch" aria-checked="false" aria-label="Master mute"></button></div></section>
<section data-pane="settings"${hide('settings')}><header class="aw-h"><h2>Settings</h2><p>Animatto v1.2.0 keeps companions, the aquarium, and timers on your Mac.</p></header><ul class="aw-list"><li>Offline and local first</li><li>No background telemetry</li><li>Reduced motion follows your system setting</li></ul></section>
</div></div></div>`;
};

const P = {};
P.index = ['Animatto — a tiny world, living on your Mac', 'Animatto is a native macOS desktop companion app with a hand-crafted cat, a desktop aquarium, ambient worlds and creator tools. Open source under Apache-2.0.',
`<div class="wrap hero"><p class="eye">A native macOS companion</p><h1>Your desktop deserves a little <em>life.</em></h1>
<p class="sub">Meet your new desktop companions. Hand-crafted characters that wander, rest, swim, and turn your Mac into a living, calm environment.</p>
<div class="pills"><span>macOS 14.6+ (Apple Silicon &amp; Intel)</span><span>100% Offline &amp; Private</span><span>Zero Background Telemetry</span><span>Apache-2.0 Open Source</span></div>
<div class="ctl"><a class="btn p" href="/download">Download for Mac</a> <a class="btn" href="#action">See it in action</a> <a class="btn" href="${GH}/releases" rel="noopener">GitHub Releases</a></div>
${appWindow()}
<p class="cap">This window is the app. Choose a companion, set the size, and launch it. Aquarium Mode covers the Clock, Weather, Calendar, and Battery widgets and leaves that companion alone.</p></div>
${sec(`<p class="eye">Original Artwork</p><h2>Meet the companions.</h2><p class="sub">Every character is custom-animated with original pixel artwork, authentic physics, and its own personality profile.</p>
<div class="comp-grid">
  <div class="comp-card">
    <img src="/sprites/cat/sit/sit_00.png" alt="Mochi the Cat sitting">
    <h3>Mochi</h3>
    <span class="tag">Surface Roamer</span>
    <p>Wanders across window titlebars, naps when you focus, purrs, and walks along the menu bar.</p>
  </div>
  <div class="comp-card">
    <img src="/sprites/aquarium/sunfin/swim_idle/swim_idle_00.png" alt="Finny the Golden Sunfin">
    <h3>Finny</h3>
    <span class="tag">Golden Sunfin</span>
    <p>Lively open-water swimmer. Curious, follows cursor motion, and darts upward for food pellets.</p>
  </div>
  <div class="comp-card">
    <img src="/sprites/aquarium/puffer/swim_idle/swim_idle_00.png" alt="Pip the Pygmy Puffer">
    <h3>Pip</h3>
    <span class="tag">Pygmy Puffer</span>
    <p>Chubby and cautious. Avoids sudden glass taps and prefers hovering near tank plants.</p>
  </div>
  <div class="comp-card">
    <img src="/sprites/aquarium/tetra/swim_idle/swim_idle_00.png" alt="Glow the Ghost Tetra">
    <h3>Glow</h3>
    <span class="tag">Ghost Tetra</span>
    <p>Luminescent schooling fish. Synchronizes swimming rhythm with companions in the tank.</p>
  </div>
  <div class="comp-card">
    <img src="/sprites/aquarium/hermitcrab/rest/rest_00.png" alt="Barnaby the Hermit Crab">
    <h3>Barnaby</h3>
    <span class="tag">Hermit Crab</span>
    <p>Patient benthic explorer. Crawls along the gravel floor and inspects mossy river stones.</p>
  </div>
</div>
<p class="cap" style="text-align:center;margin-top:24px"><a href="/features">Explore all companion capabilities &rarr;</a></p>`)}
${sec(`<div id="action"><p class="eye">Interactive Showcase</p><h2>See Animatto in action.</h2><p class="sub">Explore the core subsystems right here in your browser, powered by real Animatto artwork and simulation logic.</p>
<div class="action-grid">
  <a class="action-card" href="/aquarium">
    <div>
      <h3>Desktop Aquarium</h3>
      <p class="desc">Turn Aquarium on and the same tank covers the Clock, Weather, Calendar, and Battery widgets. Your companion keeps walking.</p>
    </div>
    <span class="lnk">Try the Interactive Aquarium &rarr;</span>
  </a>
  <a class="action-card" href="/ambient-worlds">
    <div>
      <h3>Ambient Worlds</h3>
      <p class="desc">A click-through atmospheric particle overlay with rain, snow, sunset, and sakura petals. Companions react dynamically to weather conditions.</p>
    </div>
    <span class="lnk">Preview Ambient Scenes &rarr;</span>
  </a>
  <a class="action-card" href="/productivity">
    <div>
      <h3>Focus &amp; Pomodoro Timers</h3>
      <p class="desc">Structured 25/5 and 50/10 productivity cycles. Your companion quietly rests while you work and celebrates your well-earned breaks.</p>
    </div>
    <span class="lnk">Try the Focus Timer &rarr;</span>
  </a>
  <a class="action-card" href="/creator-studio">
    <div>
      <h3>Creator Studio</h3>
      <p class="desc">On-device Apple Vision Magic Eraser for custom sprite packs, AI sprite generation, and community companion pack imports.</p>
    </div>
    <span class="lnk">Explore Creator Studio &rarr;</span>
  </a>
</div></div>`)}
${sec(`<p class="eye">Day in the Life</p><h2>Your desktop through the day.</h2><p class="sub">Animatto blends seamlessly into your macOS workflow, providing calm company without distraction.</p>
<div class="timeline">
  <div class="t-step">
    <span class="t-time">09:00 AM</span>
    <h3>Morning Kickoff</h3>
    <p>Your companion yawns and stretches across your menu bar as you open your morning calendar and emails.</p>
  </div>
  <div class="t-step">
    <span class="t-time">11:30 AM</span>
    <h3>Deep Work Sprint</h3>
    <p>Start a 25-minute Pomodoro. Your cat curls up atop your code editor while gentle rain particles drift in the background.</p>
  </div>
  <div class="t-step">
    <span class="t-time">02:00 PM</span>
    <h3>Afternoon Break</h3>
    <p>Tap the desktop aquarium widget to feed Finny and Pip between meetings, giving your eyes a restful pause.</p>
  </div>
  <div class="t-step">
    <span class="t-time">06:00 PM</span>
    <h3>Golden Hour</h3>
    <p>A sunset atmosphere warms your display. Your companion purrs contentedly as you wrap up your day's work.</p>
  </div>
</div>`)}
${sec(`<div class="two"><div><p class="eye">Open Core Architecture</p><h2>Free is genuinely useful.</h2><p class="sub">The entire core companion application is Apache-2.0 open source. All companions, physics, desktop aquarium, ambient worlds, timers, and offline privacy features are free forever.</p><div class="ctl"><a class="btn" href="/pricing">View Pricing &amp; Entitlements</a> <a class="btn" href="${GH}" rel="noopener">GitHub</a></div></div><ul class="list">
<li><b>Native Swift &amp; AppKit</b>Engineered specifically for macOS 14.6+ with low memory and battery-efficient timers. <a href="/product">Product architecture</a></li>
<li><b>100% Offline Privacy</b>Zero background analytics, no telemetry SDKs, and local memory on your Mac. <a href="/privacy">Privacy policy</a></li>
<li><b>Desktop aquarium</b>Covers the Apple widgets you already have. It does not replace a companion. <a href="/aquarium">Try the same controls</a></li>
<li><b>Community &amp; Custom Sprites</b>Import your own packs or create custom companions with Creator Studio. <a href="/creator-studio">Creator tools</a></li></ul></div>`)}`];

P.product = ['Product', 'What Animatto is and how it works.', head('Product', 'A living desktop for your Mac.', 'Animatto is a native Swift, SwiftUI and AppKit application that gives your Mac desktop companions and environments.', 'Product') +
sec(`<dl><dt>Platform</dt><dd>macOS 14.6 or later, Apple Silicon and Intel. Mac only.</dd><dt>Where to get it</dt><dd>GitHub Releases, linked from the Download page on this website. There is no Mac App Store listing.</dd><dt>Companions</dt><dd>Borderless windows driven by a physics loop. They walk on application windows and can walk along the menu bar. Launch them from the library.</dd><dt>Aquarium</dt><dd>A separate switch. It covers the Clock, Weather, Calendar, and Battery widgets. Turning it off shows those widgets again. It does not turn a companion into a fish.</dd><dt>Ambient layer</dt><dd>Weather particles render in a click-through overlay, so clicks reach the apps beneath.</dd><dt>Control</dt><dd>The menu bar lists roaming companions and has the Aquarium switch.</dd></dl>`)];

P.features = ['Features', 'Everything Animatto does today, based on the repository.', head('Features', 'What is in the app.', '', 'Features') + sec(`<dl>
<dt>Companions</dt><dd>Roaming, walking, running, jumping, falling, gravity, surface collision, window traversal, menu bar walking, drag and fling, multiple companions.</dd>
<dt>Personality</dt><dd>Ten archetypes with needs (energy, happiness, curiosity, boredom), contextual dialogue, quiet mode and anti-spam behaviour. <a href="/productivity#personality">Preview archetypes</a></dd>
<dt>Memory and social</dt><dd>Local memory of interactions and companion-to-companion encounters. Stored on your Mac.</dd>
<dt>Aquarium</dt><dd>Four original species inside covers that sit on the Clock, Weather, Calendar, and Battery widgets. Companions launched from the library stay companions. <a href="/aquarium">Try the same controls</a></dd>
<dt>Ambient Worlds</dt><dd>Rain, snow, fog, sunlight beams, wind dust, falling leaves, cherry blossom petals, fireflies, rising steam and ocean waves. Eight built-in presets (Rainy Day, Enchanted Forest, Winter Calm, Sunset, Cosmic Dream, Sakura Garden, Cozy Café, Ocean), custom presets, <code>.animattopack</code> export and import, Open-Meteo weather sync, Inverse Weather Mode and a four-rarity collectible minigame.</dd>
<dt>Creator Studio</dt><dd>Magic Eraser (Apple Vision, on-device), AI sprite generation, community browser and imports. <a href="/creator-studio">Details</a></dd>
<dt>Productivity</dt><dd>Focus timers (5, 15, 30, 60 minutes) and Pomodoro (25/5, 50/10). <a href="/productivity">Try it</a></dd>
<dt>Audio</dt><dd>Footsteps, purring and aquarium sounds with master mute.</dd>
<dt>Integrations</dt><dd>Discord Rich Presence, Spotify and Apple Music status, GitHub Releases update checks. Privacy Shield stops background monitors instantly.</dd>
<dt>Accessibility &amp; Languages</dt><dd>Reduced Motion support and ambient atmosphere localization across 11 languages: English, Hindi, Japanese, Korean, Simplified and Traditional Chinese, Spanish, French, German, Italian, and Brazilian Portuguese.</dd></dl>`)];

P.aquarium = ['Aquarium', 'Aquarium Mode covers the Clock, Weather, Calendar, and Battery widgets. Companions stay companions.', head('Aquarium', 'The widgets become the tank.', 'Aquarium is a cover for the desktop widgets you already have. Launching a companion is a different button.', 'Aquarium') + sec(`${appWindow('aquarium')}
<p class="cap">The switch covers the four widgets. Launch a companion from Library and it keeps walking on the window.</p>`) + sec(`${chips('aq-themes', 'Water theme')}${chips('aq-sizes', 'Widget size')}
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

P.pricing = ['Pricing', 'Animatto is free under Apache-2.0. Checkout is not live.', head('Pricing', 'The app is free.', 'Apache-2.0 already covers the published macOS app. There is no purchase to make.', 'Pricing') + sec(`<table><thead><tr><th scope="col">What you get</th><th scope="col">Today</th></tr></thead><tbody>
<tr><td>Companions, physics, personality, dialogue, and local memory</td><td>Included</td></tr>
<tr><td>Aquarium covers on Apple desktop widgets, Ambient Worlds, imports, and timers</td><td>Included</td></tr>
<tr><td>Cloud sync, a hosted LLM, and a creator marketplace</td><td>Not built</td></tr>
<tr><td><b>Price</b></td><td><b>$0</b></td></tr></tbody></table>
<button class="btn" disabled aria-disabled="true">Purchases aren’t open yet</button>
${note('Checkout is not connected to this page. ENABLE_PRODUCTION_PAYMENTS stays off. Older notes that mention Lifetime Pro or Founder Supporter prices are not a current offer and do not license the Apache-2.0 source.')}`)];

P.download = ['Download', 'Download Animatto for Mac from GitHub Releases. This website links to that release.', head('Download', 'Get Animatto for Mac.', 'The app is released on GitHub. This page is the other place to get that same file. macOS 14.6 or later.', 'Download') + sec(`<div class="two"><div class="rel" data-demo="release" aria-live="polite"><p class="note" style="margin-bottom:16px">Distribution is GitHub Releases only. There is no Mac App Store build. The file below is whatever GitHub currently publishes for this repository.</p><p data-state>Checking GitHub for the latest release…</p><div data-out hidden><h3 data-tag></h3><p class="mut" data-date></p><ul class="list" data-assets></ul><h3 style="margin-top:20px">Release notes</h3><pre data-notes></pre></div><p style="margin-top:16px"><a class="btn p" data-fallback href="${GH}/releases">View GitHub Releases</a></p></div>
<div><h3>Install</h3><ol><li>Open the DMG and drag Animatto into Applications.</li><li>Open Animatto.</li><li>If macOS warns about an unidentified developer, Control-click the app, choose Open, then confirm.</li></ol><p class="mut">Some releases may be ad-hoc signed and not notarized. Never disable Gatekeeper globally. To check a download run <code>shasum -a 256 Animatto.dmg</code> and compare it with a checksum published on the release. If none is published, the page says so.</p></div></div>`)];

P.faq = ['FAQ', 'Answers about installing, compatibility, privacy, features and pricing for Animatto.', head('FAQ', 'Questions, answered.', '', 'FAQ') + sec(`<div style="max-width:760px">${[
['Is Animatto Mac only?', 'Yes. It is a native macOS app: macOS 14.6 or later, Apple Silicon and Intel.'],
['Does the aquarium need its own app window?', 'Aquarium Mode covers the Clock, Weather, Calendar, and other Apple desktop widgets. Companions you launch from the library stay companions.'],
['Why does macOS show a security warning?', 'Some releases are not notarized. Control-click the app, choose Open and confirm once.'],
['Where do I download Animatto?', 'From GitHub Releases, or from the Download page on this website. Both point at the same files. There is no Mac App Store version.'],
['How do I update?', 'Animatto checks GitHub Releases. You can also download the newer file from this website.'],
['Does it collect telemetry?', 'The repository states there are no analytics SDKs, ad trackers or background telemetry. See Privacy for optional network features.'],
['Does Magic Eraser upload images?', 'No. It uses Apple’s Vision framework on your Mac.'],
['Does it work offline?', 'Core companion features do. Weather sync, AI generation, Discord and update checks use the network.'],
['How much does Animatto cost?', 'The published app is free under Apache-2.0. Checkout is not live.'],
['Are purchases live?', 'No. The pricing page does not link to checkout, and production payments stay off.'],
['Can I use my own characters?', 'You can import packs you own. Respect their license; Animatto only bundles its original artwork.']
].map(([q, a]) => `<details><summary>${q}</summary><p>${a}</p></details>`).join('')}</div>`)];

P.privacy = ['Privacy', 'How Animatto and this website handle your data.', head('Privacy', 'Local first.', '', 'Privacy') + sec(`<dl><dt>The app</dt><dd>Companion memory and preferences are stored locally. The repository documents zero analytics SDKs, ad trackers or background telemetry.</dd><dt>On-device</dt><dd>Magic Eraser runs with Apple Vision. Nothing is uploaded.</dd><dt>Optional network use</dt><dd>Open-Meteo weather sync, AI sprite generation through a configured provider, GitHub Releases update checks. Discord Rich Presence talks to the local Discord socket, and Spotify and Apple Music status is read through AppleScript on your Mac.</dd><dt>Payments</dt><dd>Not live. When enabled, payment goes through an external hosted provider and license activation involves license data.</dd><dt>This website</dt><dd>This site uses Vercel Web Analytics for anonymous, aggregated traffic statistics, including page views, referrers, approximate location, browser, operating system, and device type. Vercel states that analytics records are not associated with an IP address, do not use third-party cookies, and that visitor session identifiers are discarded after 24 hours. This applies only to the website; the Animatto macOS app does not use this analytics integration. The Download page also requests GitHub's public Releases API from your browser, so GitHub receives that request. See <a href="https://vercel.com/docs/analytics/privacy-policy" rel="noopener">Vercel's analytics privacy details</a>.</dd></dl><p class="cap">This is a plain-language summary, not legal advice. See <a href="${GH}/blob/main/SECURITY.md" rel="noopener">SECURITY.md</a>.</p>`)];

P.licensing = ['Licensing', 'Animatto is Apache-2.0 open source. Asset and audio licensing information.', head('Licensing', 'Apache-2.0 at the core.', '', 'Licensing') + sec(`<dl><dt>Application</dt><dd>Apache License 2.0. <a href="${GH}/blob/main/LICENSE" rel="noopener">Read the license</a>.</dd><dt>Artwork</dt><dd>The cat and aquarium sprites are original Animatto artwork. Each folder under <code>sprites/</code> carries its own attribution and license file. See <a href="${GH}/blob/main/docs/ASSET_LICENSE_AUDIT.md" rel="noopener">the asset audit</a>.</dd><dt>Audio</dt><dd><a href="${GH}/blob/main/docs/AUDIO_LICENSES.md" rel="noopener">Audio licenses</a>.</dd><dt>Payments</dt><dd>Not live. The Apache-2.0 grant already covers the published source. Checkout stays in test mode.</dd><dt>Trademarks</dt><dd>Mac and macOS are trademarks of Apple Inc. Animatto is not affiliated with Apple.</dd></dl>`)];

P.support = ['Support', 'Get help with Animatto: report bugs, request features and report security issues.', head('Support', 'Talk to the humans.', '', 'Support') + sec(`<dl><dt>Bugs and features</dt><dd><a href="${GH}/issues" rel="noopener">Open a GitHub issue</a></dd><dt>Installation help</dt><dd>Start with <a href="/download">Download</a> and <a href="/faq">FAQ</a>, then open an issue.</dd><dt>Security</dt><dd><a href="${GH}/blob/main/SECURITY.md" rel="noopener">Security policy</a></dd><dt>Contributing</dt><dd><a href="${GH}/blob/main/CONTRIBUTING.md" rel="noopener">Contribution guide</a></dd><dt>Premium and payments</dt><dd>Not live yet. No payment support channel exists to publish.</dd></dl>`)];

const layout = (slug, [title, desc, body]) => {
  const url = `${SITE}/${slug === 'index' ? '' : slug}`, full = slug === 'index' ? title : `${title} — Animatto`;
  return `<!DOCTYPE html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
<title>${full}</title><meta name="description" content="${desc}"><link rel="canonical" href="${url}">
<link rel="icon" type="image/png" sizes="32x32" href="/assets/favicon.png?v=20261104">
<link rel="icon" type="image/png" sizes="16x16" href="/assets/favicon.png?v=20261104">
<link rel="icon" type="image/x-icon" href="/favicon.ico?v=20261104">
<link rel="shortcut icon" href="/favicon.ico?v=20261104">
<link rel="apple-touch-icon" sizes="180x180" href="/assets/apple-touch-icon.png?v=20261104">
<meta property="og:type" content="website"><meta property="og:site_name" content="Animatto"><meta property="og:title" content="${full}"><meta property="og:description" content="${desc}"><meta property="og:url" content="${url}"><meta property="og:image" content="${SITE}/assets/og-image.png">
<meta name="twitter:card" content="summary_large_image"><meta name="twitter:title" content="${full}"><meta name="twitter:description" content="${desc}"><meta name="twitter:image" content="${SITE}/assets/og-image.png">
<link rel="stylesheet" href="/css/site.css"></head><body>
<a class="skip" href="#main">Skip to content</a>
<header><div class="wrap"><a class="logo" href="/"><img src="/assets/app_icon.png" alt="" width="32" height="32">Animatto</a>
<button id="mb" class="btn s" aria-expanded="false" aria-controls="nv">Menu</button>
<nav id="nv" aria-label="Main">${NAV.map(([s, l]) => `<a href="/${s}"${s === slug ? ' aria-current="page"' : ''}>${l}</a>`).join('')}<a href="/download" class="btn p s"${slug === 'download' ? ' aria-current="page"' : ''}>Download</a></nav></div></header>
<main id="main">${body}</main>
<footer><div class="wrap"><div class="cols">${FOOT.map(([h, l]) => `<div><h2>${h}</h2>${l.map(([s, t]) => `<a href="/${s}">${t}</a>`).join('')}</div>`).join('')}<div><h2>Project</h2><a href="${GH}" rel="noopener">GitHub</a><a href="${GH}/releases" rel="noopener">Releases</a><a href="${GH}/blob/main/LICENSE" rel="noopener">Apache-2.0</a></div></div><p style="margin-top:24px">Animatto is open source. Mac and macOS are trademarks of Apple Inc.</p></div></footer>
<script type="module" src="/js/site.js"></script>
<script defer src="https://cdn.vercel-insights.com/v1/script.js"></script></body></html>
`;
};
const files = Object.entries(P);
for (const [slug, page] of files) fs.writeFileSync(path.join(root, slug === 'index' ? 'index.html' : `${slug}.html`), layout(slug, page));
const today = new Date().toISOString().slice(0, 10);
fs.writeFileSync(path.join(root, 'sitemap.xml'), `<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n${Object.keys(P).map(s => `  <url><loc>${SITE}/${s === 'index' ? '' : s}</loc><lastmod>${today}</lastmod></url>`).join('\n')}\n</urlset>\n`);
fs.writeFileSync(path.join(root, 'robots.txt'), `User-agent: *\nAllow: /\nDisallow: /api/\n\nSitemap: ${SITE}/sitemap.xml\n`);
console.log(`Built ${Object.keys(P).length} pages for ${SITE}`);
