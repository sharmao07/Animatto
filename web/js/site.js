const $ = (s, r = document) => r.querySelector(s);
const mb = $('#mb'), nv = $('#nv');
if (mb && nv) {
  mb.onclick = () => mb.setAttribute('aria-expanded', nv.classList.toggle('open'));
  nv.onclick = e => {
    if (e.target.tagName === 'A') {
      nv.classList.remove('open');
      mb.setAttribute('aria-expanded', 'false');
    }
  };
  addEventListener('keydown', e => {
    if (e.key === 'Escape' && nv.classList.contains('open')) {
      nv.classList.remove('open');
      mb.setAttribute('aria-expanded', 'false');
      mb.focus();
    }
  });
}

const ALLOWED_DOWNLOAD_HOSTS = new Set([
  'github.com',
  'api.github.com',
  'raw.githubusercontent.com',
  'objects.githubusercontent.com'
]);

// Inside Animatto Product Showcase Tab Controller
const showcaseTitles = {
  library: 'Animatto — Companions Library',
  aquarium: 'Animatto — Aquarium Mode (Desktop Widget Transformation)',
  ambient: 'Animatto — Ambient Worlds & Dynamic Weather',
  productivity: 'Animatto — Focus Sessions & Pomodoro',
  workshop: 'Animatto — Creator Studio & Apple Vision Magic Eraser',
  audio: 'Animatto — Independent Multi-Channel Audio Console'
};

function initShowcase(root) {
  const tabs = root.querySelectorAll('[role="tab"]');
  const slides = root.querySelectorAll('.showcase-slide');
  const titleEl = root.querySelector('[data-showcase-title]');

  function activateTab(tab) {
    const tabId = tab.dataset.tab;
    tabs.forEach(t => {
      const active = t === tab;
      t.classList.toggle('active', active);
      t.setAttribute('aria-selected', active ? 'true' : 'false');
      t.tabIndex = active ? 0 : -1;
    });

    slides.forEach(slide => {
      if (slide.dataset.slide === tabId) {
        slide.hidden = false;
        slide.classList.add('active');
      } else {
        slide.hidden = true;
        slide.classList.remove('active');
      }
    });

    if (titleEl && showcaseTitles[tabId]) {
      titleEl.textContent = showcaseTitles[tabId];
    }
  }

  tabs.forEach((tab, index) => {
    tab.addEventListener('click', () => activateTab(tab));

    tab.addEventListener('keydown', e => {
      let targetTab = null;
      if (e.key === 'ArrowRight' || e.key === 'ArrowDown') {
        e.preventDefault();
        targetTab = tabs[(index + 1) % tabs.length];
      } else if (e.key === 'ArrowLeft' || e.key === 'ArrowUp') {
        e.preventDefault();
        targetTab = tabs[(index - 1 + tabs.length) % tabs.length];
      } else if (e.key === 'Home') {
        e.preventDefault();
        targetTab = tabs[0];
      } else if (e.key === 'End') {
        e.preventDefault();
        targetTab = tabs[tabs.length - 1];
      }

      if (targetTab) {
        targetTab.focus();
        activateTab(targetTab);
      }
    });
  });
}

document.querySelectorAll('[data-showcase="inside-animatto"]').forEach(initShowcase);

const demos = {
  async release(root) {
    const st = $('[data-state]', root), out = $('[data-out]', root);
    const fail = m => { st.textContent = m; };
    try {
      let r = await fetch('https://api.github.com/repos/sharmao07/Animatto/releases/latest', {
        headers: { Accept: 'application/vnd.github+json' }
      });
      let j;
      if (r.status === 404) {
        const rPre = await fetch('https://api.github.com/repos/sharmao07/Animatto/releases?per_page=5', {
          headers: { Accept: 'application/vnd.github+json' }
        });
        if (rPre.ok) {
          const list = await rPre.json();
          if (Array.isArray(list) && list.length > 0) j = list[0];
        }
        if (!j) return fail('No published release yet. Use the GitHub Releases link below.');
      } else if (r.status === 403 || r.status === 429) {
        return fail('GitHub rate limit reached. Use the GitHub Releases link below.');
      } else if (!r.ok) {
        return fail('Release information is unavailable. Use the GitHub Releases link below.');
      } else {
        j = await r.json();
      }
      st.hidden = true;
      out.hidden = false;
      const isPre = Boolean(j.prerelease);
      $('[data-tag]', root).textContent = (j.name || j.tag_name) + (isPre ? ' (Nightly Prerelease)' : '');
      $('[data-date]', root).textContent = (isPre ? 'Nightly Prerelease · ' : '') + 'Released ' + new Date(j.published_at).toLocaleDateString(undefined, { year: 'numeric', month: 'long', day: 'numeric' }) + ' · macOS 14.6 or later';
      $('[data-notes]', root).textContent = (j.body || 'No release notes published.').slice(0, 4000);
      const ul = $('[data-assets]', root), notes = j.body || '';
      const ok = u => {
        try {
          const p = new URL(u);
          return p.protocol === 'https:' && ALLOWED_DOWNLOAD_HOSTS.has(p.hostname.toLowerCase());
        } catch {
          return false;
        }
      };
      const assets = (j.assets || []).filter(a => ok(a.browser_download_url));
      if (!assets.length) {
        const li = document.createElement('li');
        li.textContent = 'This release has no downloadable assets. Use the GitHub Releases link below.';
        ul.append(li);
      }
      assets.forEach(a => {
        const li = document.createElement('li'), b = document.createElement('b'), l = document.createElement('a'), m = document.createElement('span');
        l.href = a.browser_download_url;
        l.textContent = a.name;
        l.rel = 'noopener';
        b.append(l);
        const mb = (a.size / 1048576).toFixed(1) + ' MB';
        let sha = (a.digest || '').startsWith('sha256:') ? a.digest.slice(7) : '';
        if (!sha) {
          const mm = notes.split('\n').find(x => x.includes(a.name) && /[a-f0-9]{64}/i.test(x));
          if (mm) sha = mm.match(/[a-f0-9]{64}/i)[0];
        }
        m.textContent = mb + ' · SHA-256: ' + (sha || 'not published for this asset');
        li.append(b, m);
        ul.append(li);
      });
    } catch {
      fail('Couldn’t reach GitHub. Use the GitHub Releases link below.');
    }
  }
};

document.querySelectorAll('[data-demo]').forEach(el => demos[el.dataset.demo]?.(el));
