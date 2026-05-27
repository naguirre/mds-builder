(function () {
  const root = document.documentElement;
  const btn = document.querySelector('[data-theme-toggle]');

  function setTheme(t) {
    root.dataset.theme = t;
    try { localStorage.setItem('theme', t); } catch (e) {}
  }

  if (btn) {
    btn.addEventListener('click', function () {
      setTheme(root.dataset.theme === 'dark' ? 'light' : 'dark');
    });
  }

  // TOC active-link tracking via IntersectionObserver.
  const headings = document.querySelectorAll('.prose h2[id], .prose h3[id]');
  const tocLinks = document.querySelectorAll('.toc-link');
  if (headings.length && tocLinks.length) {
    const byId = {};
    tocLinks.forEach(function (l) {
      const id = l.getAttribute('href').slice(1);
      byId[id] = l;
    });
    const io = new IntersectionObserver(function (entries) {
      entries.forEach(function (e) {
        const link = byId[e.target.id];
        if (!link) return;
        if (e.isIntersecting) {
          tocLinks.forEach(function (l) { l.classList.remove('is-active'); });
          link.classList.add('is-active');
        }
      });
    }, { rootMargin: '-20% 0px -70% 0px' });
    headings.forEach(function (h) { io.observe(h); });
  }
  // ---- Sidebar collapse ----
  document.querySelectorAll('[data-sidebar-toggle]').forEach(function (btn) {
    btn.addEventListener('click', function () {
      const collapsed = root.dataset.sidebar === 'collapsed';
      if (collapsed) {
        delete root.dataset.sidebar;
        try { localStorage.removeItem('sidebar'); } catch (e) {}
      } else {
        root.dataset.sidebar = 'collapsed';
        try { localStorage.setItem('sidebar', 'collapsed'); } catch (e) {}
      }
    });
  });

  // ---- Search modal (Pagefind) ----
  const trigger = document.querySelector('[data-search-trigger]');
  const modal = document.querySelector('[data-search-modal]');
  let pfInited = false;

  function openSearch() {
    if (!modal) return;
    modal.dataset.open = 'true';
    if (!pfInited && window.PagefindUI) {
      try {
        new window.PagefindUI({
          element: '#pagefind-search',
          showSubResults: true,
          showImages: false,
          autofocus: true,
        });
        pfInited = true;
      } catch (e) { console.warn('Pagefind init failed', e); }
    }
    requestAnimationFrame(function () {
      const input = modal.querySelector('input');
      if (input) input.focus();
    });
  }
  function closeSearch() { if (modal) modal.dataset.open = 'false'; }

  if (trigger) trigger.addEventListener('click', openSearch);
  if (modal) modal.addEventListener('click', function (e) {
    if (e.target === modal) closeSearch();
  });
  document.addEventListener('keydown', function (e) {
    if ((e.metaKey || e.ctrlKey) && e.key === 'k') {
      e.preventDefault();
      if (modal && modal.dataset.open === 'true') closeSearch(); else openSearch();
    } else if (e.key === 'Escape' && modal && modal.dataset.open === 'true') {
      closeSearch();
    }
  });

  // ---- Code block Copy buttons ----
  document.querySelectorAll('.prose pre').forEach(function (pre) {
    if (pre.classList.contains('mermaid')) return;
    const code = pre.querySelector('code');
    if (!code) return;
    const wrap = document.createElement('div');
    wrap.className = 'code-block';
    pre.parentNode.insertBefore(wrap, pre);
    wrap.appendChild(pre);
    const btn = document.createElement('button');
    btn.className = 'code-copy';
    btn.type = 'button';
    btn.setAttribute('aria-label', 'Copy code');
    btn.innerHTML = '<svg viewBox="0 0 24 24" width="14" height="14" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect width="14" height="14" x="8" y="8" rx="2" ry="2"/><path d="M4 16c-1.1 0-2-.9-2-2V4c0-1.1.9-2 2-2h10c1.1 0 2 .9 2 2"/></svg>';
    wrap.appendChild(btn);
    btn.addEventListener('click', async function () {
      try {
        await navigator.clipboard.writeText(code.innerText);
        btn.classList.add('is-copied');
        btn.innerHTML = '<svg viewBox="0 0 24 24" width="14" height="14" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="20 6 9 17 4 12"/></svg>';
        setTimeout(function () {
          btn.classList.remove('is-copied');
          btn.innerHTML = '<svg viewBox="0 0 24 24" width="14" height="14" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect width="14" height="14" x="8" y="8" rx="2" ry="2"/><path d="M4 16c-1.1 0-2-.9-2-2V4c0-1.1.9-2 2-2h10c1.1 0 2 .9 2 2"/></svg>';
        }, 1500);
      } catch (e) {}
    });
  });

  // ---- Tabs ----
  document.querySelectorAll('[data-tabs]').forEach(function (group) {
    const triggers = group.querySelectorAll('.tabs-trigger');
    const panels = group.querySelectorAll('.tabs-panel');
    triggers.forEach(function (t) {
      t.addEventListener('click', function () {
        const target = t.dataset.tabTarget;
        triggers.forEach(function (x) {
          const on = x === t;
          x.classList.toggle('is-active', on);
          x.setAttribute('aria-selected', on ? 'true' : 'false');
        });
        panels.forEach(function (p) {
          p.classList.toggle('is-active', p.id === target);
        });
      });
    });
  });

  // ---- Heading anchor links ----
  document.querySelectorAll('.prose h2[id], .prose h3[id], .prose h4[id]').forEach(function (h) {
    const a = document.createElement('a');
    a.className = 'heading-anchor';
    a.href = '#' + h.id;
    a.setAttribute('aria-label', 'Link to ' + (h.textContent || 'section'));
    a.innerHTML = '<svg viewBox="0 0 24 24" width="14" height="14" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M10 13a5 5 0 0 0 7.54.54l3-3a5 5 0 0 0-7.07-7.07l-1.72 1.71"/><path d="M14 11a5 5 0 0 0-7.54-.54l-3 3a5 5 0 0 0 7.07 7.07l1.71-1.71"/></svg>';
    h.appendChild(a);
  });

  // ---- Copy markdown source ----
  const copyBtn = document.querySelector('[data-copy-markdown]');
  if (copyBtn) {
    copyBtn.addEventListener('click', async function () {
      const url = copyBtn.dataset.copyMarkdown;
      if (!url) return;
      try {
        const r = await fetch(url);
        const text = await r.text();
        await navigator.clipboard.writeText(text);
        copyBtn.classList.add('is-copied');
        const label = copyBtn.querySelector('.page-action-label');
        const prev = label ? label.textContent : null;
        if (label) label.textContent = 'Copied';
        setTimeout(function () {
          copyBtn.classList.remove('is-copied');
          if (label && prev) label.textContent = prev;
        }, 1500);
      } catch (e) { console.warn('Copy failed', e); }
    });
  }
})();
