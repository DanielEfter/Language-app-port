let initialized = false;

const HEBREW_RE = /[\u0590-\u05FF]/;
const LATIN_RE = /[A-Za-z\u00C0-\u00D6\u00D8-\u00F6\u00F8-\u00FF]/;

function applyBidiFixes(root: ParentNode) {
  const nodes = root.querySelectorAll<HTMLElement>('[data-bidi-auto], [dir="auto"]');

  nodes.forEach((el) => {
    const text = el.textContent || '';
    if (!text.trim()) return;

    const hasHebrew = HEBREW_RE.test(text);
    const hasLatin = LATIN_RE.test(text);

    if (hasHebrew && !hasLatin) {
      el.setAttribute('dir', 'rtl');
      if (!el.getAttribute('lang')) {
        el.setAttribute('lang', 'he');
      }

      const align = getComputedStyle(el).textAlign;
      if (!el.style.textAlign && (align === 'start' || align === 'left' || align === 'justify')) {
        el.style.textAlign = 'right';
      }
    } else if (hasLatin && !hasHebrew) {
      el.setAttribute('dir', 'ltr');
      if (!el.getAttribute('lang')) {
        el.setAttribute('lang', 'es');
      }

      const align = getComputedStyle(el).textAlign;
      if (!el.style.textAlign && (align === 'start' || align === 'right' || align === 'justify')) {
        el.style.textAlign = 'left';
      }
    }

    if (!el.style.unicodeBidi) {
      el.style.unicodeBidi = 'isolate';
    }
  });
}

export function ensureCrossDeviceRendering() {
  if (initialized || typeof document === 'undefined') return;
  initialized = true;

  const root = document.documentElement;
  
  // Prevent automatic translation
  root.setAttribute('translate', 'no');
  root.classList.add('notranslate');
  
  // Add meta tag if missing
  if (!document.querySelector('meta[name="google"][content="notranslate"]')) {
    const meta = document.createElement('meta');
    meta.name = 'google';
    meta.content = 'notranslate';
    document.head.appendChild(meta);
  }

  if (!root.getAttribute('dir')) {
    root.setAttribute('dir', 'rtl');
  }
  if (!root.getAttribute('lang')) {
    root.setAttribute('lang', 'he');
  }

  if (document.body) {
    applyBidiFixes(document.body);

    const observer = new MutationObserver((mutations) => {
      for (const mutation of mutations) {
        mutation.addedNodes.forEach((node) => {
          if (node.nodeType === Node.ELEMENT_NODE) {
            applyBidiFixes(node as ParentNode);
          }
        });
      }
    });

    observer.observe(document.body, { childList: true, subtree: true });
  }
}
