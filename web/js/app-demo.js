import { catImg } from './sprites.js';
const RM = matchMedia('(prefers-reduced-motion:reduce)').matches;
const $ = (s, r) => r.querySelector(s);
const $$ = (s, r) => [...r.querySelectorAll(s)];
const TITLES = {
  library: ['Companions Library', 'Manage, inspect, and launch roaming desktop companions'],
  aquarium: ['Aquarium Mode', 'Covers the Clock, Weather, Calendar, and other Apple desktop widgets. Companions you launch from the library stay companions.'],
  ambient: ['Ambient Worlds & Weather', 'Immersive atmospheric weather systems and seasonal particles'],
  workshop: ['Creator Studio & AI Workshop', 'Offline background removal, preset crafting, and community sprites'],
  productivity: ['Productivity & Focus Timer', 'Integrated Pomodoro timer with companion encouragement states'],
  audio: ['Audio Console & Soundscape', 'Independent companion voice, movement, weather, and UI channel mix'],
  settings: ['Application Preferences', 'Physics, system startup, personality memory, and display options']
};
const ACCENTS = [
  ['Coral Bunny', '#FF5A5F', '#17181b'],
  ['Ocean Blue', '#007AFF', '#fff'],
  ['Emerald', '#34C759', '#102216'],
  ['Sunset Orange', '#FF9500', '#1a1000'],
  ['Royal Violet', '#AF52DE', '#fff'],
  ['System Accent', '#0A84FF', '#fff']
];
const TRAITS = [
  ['energy', 'Energetic', 'Sluggish ↔ Hyperactive'],
  ['laziness', 'Lazy', 'Active ↔ Couch Potato'],
  ['playfulness', 'Playful', 'Serious ↔ Non-Stop Fun'],
  ['sociability', 'Sociable', 'Introverted ↔ Social Butterfly'],
  ['shyness', 'Shy', 'Bold ↔ Timid & Elusive'],
  ['independence', 'Independent', 'Attentive ↔ Free Spirit'],
  ['attentionSeeking', 'Attention Seeking', 'Aloof ↔ Craving Interaction'],
  ['curiosity', 'Curious', 'Indifferent ↔ Inquisitive Explorer'],
  ['mischief', 'Mischievous', 'Orderly ↔ Agent of Chaos'],
  ['sarcasm', 'Sarcastic', 'Earnest ↔ Sharp Wit'],
  ['supportiveness', 'Supportive', 'Neutral ↔ Devoted Cheerleader']
];
const TOPICS = [
  ['coding', 'Coding & Programming'],
  ['gaming', 'Gaming'],
  ['music', 'Music'],
  ['art', 'Art & Drawing'],
  ['anime', 'Anime & Shows'],
  ['study', 'Study & Reading'],
  ['relaxation', 'Relaxation & Breaks']
];
const PREFS = [['like', 'Loves'], ['interested', 'Interested'], ['neutral', 'Neutral'], ['dislike', 'Dislikes']];

export async function initApp(root) {
  const deskSurface = $('[data-desktop-surface]', root) || root;
  const catEl = $('[data-cat]', root);
  const cat = catImg(catEl, RM);
  const dialog = $('[data-dialog]', root);
  const appWin = $('.appwin', root);
  let section = root.dataset.open === 'aquarium' ? 'aquarium' : 'library';
  let roaming = true, aquarium = root.dataset.open === 'aquarium', pinned = false, menuWalk = false, customSrc = '';
  let picked = $('[data-pet][aria-pressed=true]', root);
  let profiles = [], arche = null, traits = {};
  let ambOn = false, ambKey = 'rainy_day', ambName = 'Rainy Day';
  let phase = 'idle', left = 25 * 60, total = 25 * 60, paused = false, tick = 0, focusMin = 25, breakMin = 5;
  const tanks = $$('.widget-tile canvas', root);
  let tankApi = null;
  let isDraggingCat = false, isDraggingWin = false;

  const ask = (title, body, ok = 'OK') => new Promise(resolve => {
    $('[data-d-title]', dialog).textContent = title;
    $('[data-d-body]', dialog).textContent = body;
    $('[data-d-ok]', dialog).textContent = ok;
    const done = v => { dialog.close(); resolve(v); };
    $('[data-d-ok]', dialog).onclick = () => done(true);
    $('[data-d-cancel]', dialog).onclick = () => done(false);
    dialog.showModal();
  });

  const spriteFor = t => t.laziness >= .7 ? 'sleep' : t.energy >= .85 ? 'run' : t.laziness >= .5 ? 'sit' : t.curiosity >= .8 ? 'walk' : t.playfulness >= .9 ? 'jump' : 'idle';

  const paintPet = () => {
    if (!picked) return;
    $('[data-name]', root).textContent = picked.dataset.label;
    const src = picked.querySelector('img').src;
    $('[data-preview]', root).src = src;
    const n = +$('[data-scale]', root).value;
    $('[data-px]', root).textContent = n + ' px';
    $('[data-preview]', root).style.width = Math.min(n, 160) + 'px';
    catEl.style.width = n + 'px';
    if (picked.dataset.custom) {
      cat.stop(); catEl.src = src; customSrc = src;
    } else {
      customSrc = '';
      cat.set(phase === 'focus' && roaming ? 'sleep' : phase === 'break' && roaming ? 'jump' : (RM ? 'sit' : picked.dataset.state));
    }
  };

  const paint = () => {
    $$('[data-pane]', root).forEach(p => { p.hidden = p.dataset.pane !== section; });
    $$('[data-nav]', root).forEach(b => b.dataset.nav === section ? b.setAttribute('aria-current', 'true') : b.removeAttribute('aria-current'));
    const [title, sub] = TITLES[section] || TITLES.library;
    $('[data-title]', root).textContent = title;
    $('[data-sub]', root).textContent = sub;
    $('[data-roam]', root).hidden = !roaming;
    $('[data-clear]', root).hidden = !roaming;
    $('[data-roam-row]', root).hidden = !roaming;
    $('[data-count]', root).textContent = roaming ? '1 roaming' : '0 roaming';
    $('[data-pop-pet]', root).hidden = !roaming;
    $('[data-pop-empty]', root).hidden = roaming;
    if (picked) $('[data-pop-name]', root).textContent = picked.dataset.label;
    catEl.classList.toggle('is-hidden', !roaming);
    catEl.classList.toggle('on-menu', menuWalk);
    $('[data-aq]', root).setAttribute('aria-checked', aquarium ? 'true' : 'false');
    $('[data-aq-badge]', root).hidden = !aquarium;
    $('[data-pill-aq]', root).hidden = !aquarium;
    $('[data-aq-state]', root).textContent = aquarium ? 'Aquarium Mode Active' : 'Off';
    $('[data-aq-btn]', root).textContent = aquarium ? 'Turn Off Aquarium Mode' : 'Turn On Aquarium Mode';
    $('[data-widget-copy]', root).textContent = aquarium
      ? '4 macOS desktop widgets are currently replaced by interactive aquariums with swimming companions.'
      : '4 macOS desktop widgets detected on screen (Clock, Weather, Calendar, Battery). Turn on Aquarium Mode to transform them directly into living aquariums.';
    $$('[data-feed-tank],[data-tap]', root).forEach(b => { b.disabled = !aquarium; });

    const wArea = $('[data-widgets-area]', root);
    if (wArea) wArea.classList.toggle('on-aq', aquarium);
    root.classList.toggle('desktop-pinned', pinned);
    $('[data-pin]', root).textContent = pinned ? 'Pinned' : 'Pin on Top';

    const muted = $('[data-mute]', root).getAttribute('aria-checked') === 'true';
    $('[data-pill-mute]', root).hidden = !muted;
    $('[data-audio-state]', root).textContent = muted ? 'Muted' : 'Active';
    paintPet();
  };

  const show = name => {
    section = name; paint();
    if (name === 'ambient') bootAmbient();
    if (name === 'workshop') bootGallery();
  };

  $$('[data-nav]', root).forEach(b => b.onclick = () => show(b.dataset.nav));
  const selectPet = b => {
    picked = b;
    $$('[data-pet]', root).forEach(x => x.setAttribute('aria-pressed', x === b ? 'true' : 'false'));
    paint();
  };
  $$('[data-pet]', root).forEach(b => b.onclick = () => selectPet(b));
  $('[data-launch]', root).onclick = () => {
    if (!picked) return;
    roaming = true;
    catEl.classList.remove('is-hidden');
    paint();
  };
  $('[data-dismiss]', root).onclick = $('[data-pop-dismiss]', root).onclick = () => {
    roaming = false;
    catEl.classList.add('is-hidden');
    paint();
  };
  $('[data-clear]', root).onclick = () => {
    roaming = false;
    catEl.classList.add('is-hidden');
    paint();
  };
  $('[data-scale]', root).oninput = paint;

  $('[data-delete-all]', root).onclick = async () => {
    if (!await ask('Delete All Companions', 'Are you sure you want to permanently delete all companions from your library at once? This will remove all saved companion files and clear any roaming desktop companions.', 'Delete All')) return;
    $$('[data-pet]', root).forEach(b => { if (!b.dataset.shipped) b.dataset.shipped = '1'; b.hidden = true; });
    roaming = false; picked = null;
    catEl.classList.add('is-hidden');
    $('[data-lib-empty]', root).hidden = false;
    $('[data-restore]', root).hidden = false;
    $('[data-insp]', root).hidden = true;
    $('[data-pet-count]', root).textContent = '0';
    paint();
  };

  $('[data-restore]', root).onclick = () => {
    $$('[data-pet]', root).forEach(b => { if (b.dataset.shipped || !b.dataset.custom) b.hidden = false; });
    $('[data-lib-empty]', root).hidden = true;
    $('[data-restore]', root).hidden = true;
    $('[data-insp]', root).hidden = false;
    const first = $('[data-pet]:not([hidden])', root);
    if (first) selectPet(first);
    $('[data-pet-count]', root).textContent = String($$('[data-pet]', root).filter(b => !b.hidden).length);
    roaming = true;
    paint();
  };

  $('[data-add]', root).onchange = e => {
    const file = e.target.files && e.target.files[0];
    if (!file) return;
    const url = URL.createObjectURL(file);
    const b = document.createElement('button');
    b.type = 'button'; b.className = 'aw-card'; b.dataset.pet = ''; b.dataset.custom = '1'; b.dataset.label = file.name.replace(/\.[^.]+$/, ''); b.dataset.state = 'idle';
    b.innerHTML = '<img alt=""><span></span>';
    b.querySelector('img').src = url; b.querySelector('span').textContent = b.dataset.label;
    b.onclick = () => selectPet(b);
    $('[data-grid]', root).append(b);
    $('[data-pet-count]', root).textContent = String($$('[data-pet]', root).filter(x => !x.hidden).length);
    $('[data-lib-empty]', root).hidden = true;
    $('[data-insp]', root).hidden = false;
    selectPet(b);
  };

  // Aquarium Mode Transformation
  const setAquarium = on => {
    aquarium = on;
    paint();
    if (aquarium) {
      ensureTanks();
    }
  };
  $('[data-aq]', root).onclick = () => setAquarium(!aquarium);
  $('[data-aq-btn]', root).onclick = () => setAquarium(!aquarium);
  $('[data-pin]', root).onclick = () => { pinned = !pinned; paint(); };

  const ensureTanks = async () => {
    if (tankApi) return;
    const { initAquarium } = await import('./aquarium.js');
    tankApi = tanks.map(cv => initAquarium(cv, { mini: true }));
  };
  $('[data-feed-tank]', root).onclick = () => tankApi && tankApi.forEach(t => t.feed());
  $('[data-tap]', root).onclick = () => tankApi && tankApi.forEach(t => t.tap());
  $('[data-theme]', root).onchange = e => tankApi && tankApi.forEach(t => t.theme(+e.target.value));
  $('[data-size]', root).onchange = e => {
    const wArea = $('[data-widgets-area]', root);
    if (wArea) wArea.dataset.size = e.target.value;
  };

  // Menu bar Popover
  $('[data-menu]', root).onclick = () => {
    const pop = $('[data-popover]', root), open = pop.hasAttribute('hidden');
    if (open) pop.removeAttribute('hidden'); else pop.setAttribute('hidden', '');
    $('[data-menu]', root).setAttribute('aria-expanded', open ? 'true' : 'false');
  };
  $('[data-pop-focus]', root).onclick = () => { show('productivity'); startPomo(); };

  // Window Controls (Close, Minimize, Restore)
  const closeWin = () => {
    if (appWin) appWin.classList.add('win-minimized');
    const dockBtn = $('[data-dock-animatto]', root);
    if (dockBtn) dockBtn.classList.remove('active');
  };
  const restoreWin = () => {
    if (appWin) appWin.classList.remove('win-minimized');
    const dockBtn = $('[data-dock-animatto]', root);
    if (dockBtn) dockBtn.classList.add('active');
    const pop = $('[data-popover]', root);
    if (pop) pop.setAttribute('hidden', '');
  };
  const closeBtn = $('[data-win-close]', root);
  if (closeBtn) closeBtn.onclick = closeWin;
  const minBtn = $('[data-win-min]', root);
  if (minBtn) minBtn.onclick = closeWin;
  const zoomBtn = $('[data-win-zoom]', root);
  if (zoomBtn) zoomBtn.onclick = () => {
    if (appWin) appWin.classList.toggle('win-maximized');
  };
  const dockBtn = $('[data-dock-animatto]', root);
  if (dockBtn) dockBtn.onclick = () => {
    if (appWin.classList.contains('win-minimized')) restoreWin();
    else closeWin();
  };
  const restoreBtn = $('[data-restore-app]', root);
  if (restoreBtn) restoreBtn.onclick = restoreWin;

  // Dragging the App Window across Desktop Surface
  const dragHandle = $('[data-win-drag-handle]', root);
  if (dragHandle && appWin) {
    let startX = 0, startY = 0, winLeft = 0, winTop = 0;
    const onWinMove = e => {
      if (!isDraggingWin) return;
      const dx = e.clientX - startX;
      const dy = e.clientY - startY;
      appWin.style.left = (winLeft + dx) + 'px';
      appWin.style.top = (winTop + dy) + 'px';
      appWin.style.transform = 'none';
    };
    const onWinUp = () => {
      isDraggingWin = false;
      document.removeEventListener('pointermove', onWinMove);
      document.removeEventListener('pointerup', onWinUp);
    };
    dragHandle.addEventListener('pointerdown', e => {
      if (e.target.closest('button')) return;
      isDraggingWin = true;
      startX = e.clientX;
      startY = e.clientY;
      const rect = appWin.getBoundingClientRect();
      const parentRect = deskSurface.getBoundingClientRect();
      winLeft = rect.left - parentRect.left;
      winTop = rect.top - parentRect.top;
      appWin.style.left = winLeft + 'px';
      appWin.style.top = winTop + 'px';
      appWin.style.transform = 'none';
      document.addEventListener('pointermove', onWinMove);
      document.addEventListener('pointerup', onWinUp);
    });
  }

  // Dragging the Companion with Mouse
  if (catEl) {
    let catStartX = 0, catStartY = 0, catLeft = 0, catTop = 0;
    const onCatMove = e => {
      if (!isDraggingCat) return;
      const deskRect = deskSurface.getBoundingClientRect();
      const newX = e.clientX - deskRect.left - catStartX;
      const newY = e.clientY - deskRect.top - catStartY;
      catEl.style.left = Math.max(0, Math.min(deskRect.width - 60, newX)) + 'px';
      catEl.style.top = Math.max(0, Math.min(deskRect.height - 60, newY)) + 'px';
    };
    const onCatUp = () => {
      isDraggingCat = false;
      catEl.classList.remove('is-dragging');
      document.removeEventListener('pointermove', onCatMove);
      document.removeEventListener('pointerup', onCatUp);
      if (picked && !picked.dataset.custom) {
        cat.set('idle');
      }
    };
    catEl.addEventListener('pointerdown', e => {
      isDraggingCat = true;
      catEl.classList.add('is-dragging');
      const catRect = catEl.getBoundingClientRect();
      catStartX = e.clientX - catRect.left;
      catStartY = e.clientY - catRect.top;
      if (picked && !picked.dataset.custom) {
        cat.set('fall');
      }
      document.addEventListener('pointermove', onCatMove);
      document.addEventListener('pointerup', onCatUp);
    });
  }

  // Live Clock for Menu Bar & Analog Clock Widget
  const updateClocks = () => {
    const now = new Date();
    const clockEl = $('[data-menubar-clock]', root);
    if (clockEl) {
      const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      let h = now.getHours();
      const ampm = h >= 12 ? 'PM' : 'AM';
      h = h % 12 || 12;
      const m = String(now.getMinutes()).padStart(2, '0');
      clockEl.textContent = `${days[now.getDay()]} ${months[now.getMonth()]} ${now.getDate()} ${h}:${m} ${ampm}`;
    }
    const hDeg = (now.getHours() % 12) * 30 + now.getMinutes() * 0.5;
    const mDeg = now.getMinutes() * 6;
    const sDeg = now.getSeconds() * 6;
    const hHand = $('[data-clock-h]', root);
    const mHand = $('[data-clock-m]', root);
    const sHand = $('[data-clock-s]', root);
    if (hHand) hHand.style.transform = `rotate(${hDeg}deg)`;
    if (mHand) mHand.style.transform = `rotate(${mDeg}deg)`;
    if (sHand) sHand.style.transform = `rotate(${sDeg}deg)`;
  };
  setInterval(updateClocks, 1000);
  updateClocks();

  // Pomodoro Focus Timer
  const fmt = s => String(Math.floor(s / 60)).padStart(2, '0') + ':' + String(s % 60).padStart(2, '0');
  const paintTimer = () => {
    $('[data-time]', root).textContent = fmt(Math.max(0, left));
    $('[data-phase]', root).textContent = phase === 'focus' ? (paused ? 'Paused' : 'Focus') : phase === 'break' ? 'Break' : phase === 'done' ? 'Done' : 'Idle';
    $('[data-cycle]', root).hidden = phase === 'idle';
    $('[data-bar]', root).style.width = total ? (100 * (1 - left / total)) + '%' : '0';
    const badge = $('[data-timer-badge]', root);
    badge.hidden = phase === 'idle';
    badge.textContent = fmt(Math.max(0, left));
    const box = $('[data-timer-actions]', root);
    box.innerHTML = '';
    const add = (label, cls, fn) => { const b = document.createElement('button'); b.type = 'button'; b.className = cls || ''; b.textContent = label; b.onclick = fn; box.append(b); };
    if (phase === 'idle' || phase === 'done') add('Start Pomodoro (25m)', 'aw-launch', startPomo);
    else {
      add(paused ? 'Resume' : 'Pause', 'aw-launch', () => { paused = !paused; });
      add('Skip Phase', '', skipPhase);
      add('Stop', '', stopTimer);
    }
    $('[data-pop-timer]', root).textContent = phase === 'idle' ? 'Focus Timer' : fmt(Math.max(0, left));
    if (roaming) paintPet();
  };
  const stopTimer = () => { clearInterval(tick); tick = 0; phase = 'idle'; paused = false; left = total = focusMin * 60; paintTimer(); };
  const arm = () => { clearInterval(tick); tick = setInterval(() => { if (paused) return; left -= 1; if (left <= 0) { if (phase === 'focus') { phase = 'break'; left = total = breakMin * 60; } else { phase = 'done'; left = 0; clearInterval(tick); } } paintTimer(); }, 1000); };
  const startPomo = () => { phase = 'focus'; paused = false; left = total = focusMin * 60; arm(); paintTimer(); };
  const skipPhase = () => { if (phase === 'focus') { phase = 'break'; left = total = breakMin * 60; } else stopTimer(); paintTimer(); };
  $('[data-focus]', root).oninput = e => { focusMin = +e.target.value; $('[data-focus-n]', root).textContent = focusMin; if (phase === 'idle') { left = total = focusMin * 60; paintTimer(); } };
  $('[data-break]', root).oninput = e => { breakMin = +e.target.value; $('[data-break-n]', root).textContent = breakMin; };

  // Audio Console
  $('[data-mute]', root).onclick = () => {
    const on = $('[data-mute]', root).getAttribute('aria-checked') !== 'true';
    $('[data-mute]', root).setAttribute('aria-checked', on ? 'true' : 'false');
    paint();
  };
  $('[data-vol]', root).oninput = e => { $('[data-vol-n]', root).textContent = e.target.value + '%'; };
  $('[data-audio-reset]', root).onclick = () => {
    $('[data-mute]', root).setAttribute('aria-checked', 'false');
    $('[data-vol]', root).value = 80; $('[data-vol-n]', root).textContent = '80%';
    $$('[data-ch]', root).forEach(b => b.setAttribute('aria-checked', 'true'));
    $$('[data-ch-vol]', root).forEach(s => { s.value = s.dataset.chVol === 'purr' ? 40 : s.dataset.chVol === 'voice' ? 60 : 70; s.disabled = false; });
    paint();
  };
  $$('[data-ch]', root).forEach(b => b.onclick = () => {
    const on = b.getAttribute('aria-checked') !== 'true';
    b.setAttribute('aria-checked', on ? 'true' : 'false');
    const slider = root.querySelector(`[data-ch-vol="${b.dataset.ch}"]`);
    if (slider) slider.disabled = !on;
  });

  // Settings & Theme Swatches
  const sw = $('[data-swatches]', root);
  ACCENTS.forEach(([name, hex, ink], i) => {
    const b = document.createElement('button');
    b.type = 'button'; b.className = 'aw-swatch'; b.style.background = '#' + hex.replace('#', ''); b.title = name; b.setAttribute('aria-label', name); b.setAttribute('aria-pressed', i === 1 ? 'true' : 'false');
    b.onclick = () => {
      root.style.setProperty('--aw', hex);
      root.style.setProperty('--aw-ink', ink);
      if (appWin) appWin.style.setProperty('--aw', hex);
      $$('.aw-swatch', root).forEach(x => x.setAttribute('aria-pressed', 'false'));
      b.setAttribute('aria-pressed', 'true');
    };
    sw.append(b);
  });
  root.style.setProperty('--aw', '#007AFF');
  root.style.setProperty('--aw-ink', '#fff');
  if (appWin) appWin.style.setProperty('--aw', '#007AFF');

  $('[data-grav]', root).oninput = e => { $('[data-grav-n]', root).textContent = (e.target.value / 10).toFixed(1) + 'x'; };
  $('[data-walk]', root).oninput = e => { $('[data-walk-n]', root).textContent = (e.target.value / 2).toFixed(1) + ' pt/t'; };
  $('[data-menuwalk]', root).onclick = () => {
    menuWalk = !menuWalk;
    $('[data-menuwalk]', root).setAttribute('aria-checked', menuWalk ? 'true' : 'false');
    paint();
  };
  $('[data-login]', root).onclick = () => {
    const b = $('[data-login]', root), on = b.getAttribute('aria-checked') !== 'true';
    b.setAttribute('aria-checked', on ? 'true' : 'false');
  };
  $('[data-reset-pos]', root).onclick = () => {
    catEl.style.left = '48%';
    catEl.style.top = '72%';
    if (appWin) {
      appWin.style.left = '';
      appWin.style.top = '';
      appWin.style.transform = '';
    }
  };
  $('[data-updates]', root).onclick = () => {
    $('[data-update-status]', root).textContent = 'This preview does not contact the update server. Download official releases from GitHub Releases.';
  };

  // Personality Matrix & Traits
  const fillTraits = () => {
    const box = $('[data-traits]', root); box.innerHTML = '';
    TRAITS.forEach(([key, label, desc]) => {
      const row = document.createElement('label'); row.className = 'aw-scale';
      const val = Math.round((traits[key] ?? .5) * 100);
      row.innerHTML = `${label} <b>${val}%</b><small>${desc}</small><input type="range" min="0" max="100" value="${val}" aria-label="${label}">`;
      row.querySelector('input').oninput = e => {
        traits[key] = e.target.value / 100;
        row.querySelector('b').textContent = e.target.value + '%';
        if (picked && !picked.dataset.custom) {
          picked.dataset.state = spriteFor(traits);
          paintPet();
        }
      };
      box.append(row);
    });
  };
  const fillInterests = () => {
    const box = $('[data-interests]', root); box.innerHTML = '';
    TOPICS.forEach(([key, label]) => {
      const row = document.createElement('label'); row.className = 'aw-scale';
      row.innerHTML = `${label} <select aria-label="${label}">${PREFS.map(([v, n]) => `<option value="${v}">${n}</option>`).join('')}</select>`;
      box.append(row);
    });
  };
  const applyArche = p => {
    arche = p;
    traits = { ...p.traits, shyness: p.traits.shyness ?? .4, independence: p.traits.independence ?? .5, attentionSeeking: p.traits.attentionSeeking ?? .4, sarcasm: p.traits.sarcasm ?? .2, supportiveness: p.traits.supportiveness ?? .5 };
    $('[data-arch-sum]', root).textContent = p.summary;
    $('[data-archetype]', root).value = p.key;
    fillTraits();
    if (picked && !picked.dataset.custom) {
      picked.dataset.state = spriteFor(traits);
      paintPet();
    }
  };

  profiles = await (await fetch('/data/personalities.json')).json();
  const sel = $('[data-archetype]', root);
  profiles.forEach(p => {
    const o = document.createElement('option');
    o.value = p.key;
    o.textContent = p.name;
    sel.append(o);
  });
  sel.onchange = () => applyArche(profiles.find(p => p.key === sel.value));
  applyArche(profiles.find(p => p.key === 'balanced') || profiles[0]);
  fillInterests();
  $('[data-preview-sheet]', root).onclick = () => ask('Behavior Preview', `Simulated from the ${arche.name} traits. Predicted tendency: ${spriteFor(traits)}. Zero telemetry, on-device offline simulation.`, 'Done');

  // Ambient Worlds & Weather
  let ambReady = false, presets = [];
  const bootAmbient = async () => {
    if (ambReady) return; ambReady = true;
    presets = await (await fetch('/data/presets.json')).json();
    const grid = $('[data-preset-grid]', root);
    presets.forEach((p, i) => {
      const b = document.createElement('button'); b.type = 'button'; b.className = 'aw-card'; b.dataset.key = p.key; b.setAttribute('aria-pressed', i === 0 ? 'true' : 'false');
      b.innerHTML = `<b></b><small></small>`; b.querySelector('b').textContent = p.name; b.querySelector('small').textContent = p.description;
      b.onclick = () => chooseAmb(p);
      grid.append(b);
    });
    const { initAmbient } = await import('./ambient.js');
    const host = document.createElement('div'); host.hidden = true; host.innerHTML = '<div data-presets></div><div data-quality></div><p data-desc></p>';
    const wrap = $('[data-amb-canvas]', root).parentElement;
    wrap.append(host);
    await initAmbient(wrap);
  };
  const chooseAmb = p => {
    ambKey = p.key; ambName = p.name;
    $('[data-amb-name]', root).textContent = p.name;
    $('[data-amb-desc]', root).textContent = p.description;
    $$('[data-preset-grid] button', root).forEach(b => b.setAttribute('aria-pressed', b.dataset.key === p.key ? 'true' : 'false'));
    const chip = $$('[data-presets] button', root).find(b => b.textContent === p.name);
    if (chip) chip.click();
  };
  $('[data-amb]', root).onclick = () => {
    ambOn = !ambOn;
    $('[data-amb]', root).setAttribute('aria-checked', ambOn ? 'true' : 'false');
    deskSurface.classList.toggle('amb-on', ambOn);
  };
  $('[data-amb-apply]', root).onclick = () => {
    ambOn = true;
    $('[data-amb]', root).setAttribute('aria-checked', 'true');
    deskSurface.classList.toggle('amb-on', true);
  };
  $('[data-amb-reset]', root).onclick = () => {
    const p = presets[0];
    if (p) chooseAmb(p);
    $('[data-intensity]', root).value = 70;
    $('[data-int]', root).textContent = '70%';
    $('[data-amb-canvas]', root).style.opacity = .7;
  };
  $('[data-intensity]', root).oninput = e => {
    $('[data-int]', root).textContent = e.target.value + '%';
    $('[data-amb-canvas]', root).style.opacity = e.target.value / 100;
  };
  $$('[data-q]', root).forEach(b => b.onclick = () => {
    $$('[data-q]', root).forEach(x => x.setAttribute('aria-pressed', 'false'));
    b.setAttribute('aria-pressed', 'true');
    const map = { low: 'Low Power', balanced: 'Balanced', high: 'High Quality' };
    const chip = $$('[data-quality] button', root).find(c => c.textContent === map[b.dataset.q]);
    if (chip) chip.click();
  });

  // Workshop
  const shopBadge = { eraser: 'Offline Local AI', ambient: 'Offline Local Ambience', db: 'Curated Catalog', presets: 'Offline Local' };
  const showShop = id => {
    $$('[data-shop]', root).forEach(b => b.setAttribute('aria-pressed', b.dataset.shop === id ? 'true' : 'false'));
    $$('[data-shop-pane]', root).forEach(p => { p.hidden = p.dataset.shopPane !== id; });
    $('[data-shop-badge]', root).textContent = shopBadge[id];
    if (id === 'presets') bootGallery();
    if (id === 'db') paintDb();
  };
  $$('[data-shop]', root).forEach(b => b.onclick = () => showShop(b.dataset.shop));
  $('[data-open-ambient]', root).onclick = () => show('ambient');
  let eraseURL = '';
  $('[data-erase-file]', root).onchange = e => {
    const file = e.target.files && e.target.files[0]; if (!file) return;
    eraseURL = URL.createObjectURL(file);
    $('[data-erase-name]', root).textContent = 'Selected: ' + file.name;
    const img = $('[data-erase-preview]', root); img.hidden = false; img.src = eraseURL;
    $('[data-erase-status]', root).textContent = '';
  };
  $('[data-erase]', root).onclick = () => {
    $('[data-erase-status]', root).textContent = eraseURL
      ? 'Apple Vision runs on-device on your Mac. Background is isolated and cleared without telemetry.'
      : 'Select an image or GIF to remove background offline.';
  };
  const paintDb = () => {
    const q = ($('[data-db-q]', root).value || '').toLowerCase();
    const ul = $('[data-db]', root); ul.innerHTML = '';
    $$('[data-pet]', root).filter(b => !b.hidden && b.dataset.label.toLowerCase().includes(q)).forEach(b => {
      const li = document.createElement('li'); li.textContent = b.dataset.label + ' · local library companion'; ul.append(li);
    });
    if (!ul.children.length) {
      const li = document.createElement('li'); li.textContent = 'No local companions match.'; ul.append(li);
    }
  };
  $('[data-db-q]', root).oninput = paintDb;
  let galleryReady = false;
  const bootGallery = () => {
    if (galleryReady || !profiles.length) return; galleryReady = true;
    const box = $('[data-gallery]', root);
    profiles.forEach(p => {
      const b = document.createElement('button'); b.type = 'button'; b.className = 'aw-card';
      b.innerHTML = '<b></b><small></small>'; b.querySelector('b').textContent = p.name; b.querySelector('small').textContent = p.summary;
      b.onclick = () => {
        applyArche(p);
        $('[data-applied]', root).textContent = `Preset Applied. ${p.name} is now the archetype for ${picked ? picked.dataset.label : 'the library'}.`;
      };
      box.append(b);
    });
  };

  // Autonomous Roaming on the Desktop (when not being dragged)
  let catX = 48, catDir = 1;
  const frame = () => {
    if (roaming && !isDraggingCat && !RM) {
      if (menuWalk) {
        catEl.style.top = '2px';
        catEl.style.transform = 'scaleY(-1)' + (catDir < 0 ? ' scaleX(-1)' : '');
      } else {
        catEl.style.top = '';
        if (picked && (picked.dataset.state === 'walk' || picked.dataset.state === 'run' || phase === 'idle')) {
          const speed = (+$('[data-walk]', root).value || 2) * 0.035;
          catX += catDir * speed;
          if (catX > 82) { catDir = -1; catEl.style.transform = 'scaleX(-1)'; }
          if (catX < 38) { catDir = 1; catEl.style.transform = ''; }
          catEl.style.left = catX + '%';
        }
      }
    }
    requestAnimationFrame(frame);
  };
  frame();

  paint();
  paintTimer();
  if (aquarium) {
    ensureTanks();
  }
  if (section === 'ambient') bootAmbient();
}
