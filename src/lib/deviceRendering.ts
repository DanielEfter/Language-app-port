export const preventBrowserTranslation = () => {
  if (typeof document === 'undefined') return;

  const root = document.documentElement;
  if (!root) return;

  // Prevent Google Translate
  root.setAttribute('translate', 'no');
  root.classList.add('notranslate');

  // Add meta tag if not exists
  if (!document.querySelector('meta[name="google"]')) {
    const meta = document.createElement('meta');
    meta.name = 'google';
    meta.content = 'notranslate';
    document.head.appendChild(meta);
  }

  // Prevent Microsoft Translator
  if (!document.querySelector('meta[name="microsoft"]')) {
    const msMeta = document.createElement('meta');
    msMeta.name = 'microsoft';
    msMeta.content = 'notranslate';
    document.head.appendChild(msMeta);
  }

  if (document.body) {
    document.body.classList.add('notranslate');
  }
};

export const ensureCrossDeviceRendering = () => {
  if (typeof document === 'undefined') return;

  const root = document.documentElement;
  if (!root) return;

  root.setAttribute('dir', 'rtl');
  root.setAttribute('lang', 'he');

  (root.style as any).textSizeAdjust = '100%';
  (root.style as any).webkitTextSizeAdjust = '100%';

  // Prevent automatic translation
  preventBrowserTranslation();

  if (document.body) {
    document.body.classList.add('device-safe');

    const isTouch = typeof window !== 'undefined'
      && window.matchMedia
      && window.matchMedia('(hover: none) and (pointer: coarse)').matches;

    if (isTouch) {
      document.body.dataset.inputMode = 'touch';
    }
  }
};
