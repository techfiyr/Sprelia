/*
 * Sprelia cookie and storage consent (first-party, no third-party scripts).
 *
 * What this site actually does today: it sets NO cookies and loads NO analytics, advertising
 * or other third-party scripts. The only thing stored is this consent choice, in the browser's
 * localStorage, because it is strictly necessary to remember the choice and not ask again.
 *
 * Optional categories exist so that any future optional feature must check consent first
 * (`window.SpreliaConsent.has('analytics')`) and stays off until the visitor opts in.
 * Changing what a category covers requires bumping CONSENT_VERSION, which asks again.
 */

export const CONSENT_VERSION = 1;
export const STORAGE_KEY = 'sprelia.consent';
/** Optional categories. "necessary" is always on and is not a choice. */
export const OPTIONAL_CATEGORIES = ['analytics', 'marketing'];

const MESSAGES = {
  en: {
    bannerLabel: 'Cookie and storage choices',
    bannerText:
      'This site does not use analytics or advertising cookies and loads no third-party scripts. Optional categories stay off unless you turn them on. We only store your choice on this device.',
    rejectAll: 'Reject all',
    acceptAll: 'Accept all',
    manage: 'Manage preferences',
    dialogTitle: 'Cookie and storage preferences',
    dialogIntro: 'Choose which optional categories this site may use. You can change this at any time from "Cookie settings" in the footer.',
    necessary: 'Strictly necessary (always on)',
    necessaryText: 'Remembers your choices on this page. Stored in your browser, not in a cookie.',
    analytics: 'Analytics',
    analyticsText: 'Not used on this site. If it is ever added, it stays off unless you turn this on.',
    marketing: 'Marketing',
    marketingText: 'Not used on this site. If it is ever added, it stays off unless you turn this on.',
    save: 'Save preferences',
    cancel: 'Cancel',
    saved: 'Your choices were saved.',
  },
};

function messages(lang) {
  const base = String(lang || 'en').toLowerCase().split('-')[0];
  return MESSAGES[base] || MESSAGES.en;
}

/** All optional categories set to one value. */
export function allChoices(value) {
  return Object.fromEntries(OPTIONAL_CATEGORIES.map((c) => [c, Boolean(value)]));
}

/** Validates a stored record. Anything unexpected (old version, tampering) counts as "no decision". */
export function parseRecord(raw) {
  if (typeof raw !== 'string' || raw.length > 1024) return null;
  let r;
  try {
    r = JSON.parse(raw);
  } catch {
    return null;
  }
  if (!r || typeof r !== 'object' || r.version !== CONSENT_VERSION) return null;
  if (typeof r.decidedAt !== 'string' || Number.isNaN(Date.parse(r.decidedAt))) return null;
  if (!r.choices || typeof r.choices !== 'object') return null;
  const choices = {};
  for (const c of OPTIONAL_CATEGORIES) {
    if (typeof r.choices[c] !== 'boolean') return null;
    choices[c] = r.choices[c];
  }
  return { version: CONSENT_VERSION, decidedAt: r.decidedAt, choices };
}

/**
 * Consent store over a Storage-like object. If storage is unavailable or throws (private
 * mode, blocked storage), the choice is kept in memory for this page only.
 */
export function createConsentStore(storage, now = () => new Date()) {
  let memory = null;

  const read = () => {
    try {
      const fromStorage = parseRecord(storage ? storage.getItem(STORAGE_KEY) : null);
      if (fromStorage) return fromStorage;
    } catch {
      /* storage unavailable */
    }
    return memory;
  };

  const write = (choices) => {
    const record = { version: CONSENT_VERSION, decidedAt: now().toISOString(), choices: { ...allChoices(false), ...choices } };
    for (const c of Object.keys(record.choices)) if (!OPTIONAL_CATEGORIES.includes(c)) delete record.choices[c];
    memory = record;
    try {
      if (storage) storage.setItem(STORAGE_KEY, JSON.stringify(record));
    } catch {
      /* keep in memory only */
    }
    return record;
  };

  return {
    get: read,
    needsDecision: () => read() === null,
    /** "necessary" is always true; optional categories only after an explicit opt-in. */
    has: (category) => category === 'necessary' || read()?.choices[category] === true,
    rejectAll: () => write(allChoices(false)),
    acceptAll: () => write(allChoices(true)),
    save: (choices) => {
      const clean = {};
      for (const c of OPTIONAL_CATEGORIES) clean[c] = choices?.[c] === true;
      return write(clean);
    },
  };
}

function safeStorage() {
  try {
    return typeof window !== 'undefined' ? window.localStorage : null;
  } catch {
    return null;
  }
}

function el(tag, attrs = {}, children = []) {
  const node = document.createElement(tag);
  for (const [k, v] of Object.entries(attrs)) {
    if (k === 'text') node.textContent = v;
    else node.setAttribute(k, v);
  }
  for (const child of children) node.append(child);
  return node;
}

/** Builds the banner and preferences dialog. No inline scripts or styles (strict CSP). */
export function initConsentUi(doc = document, store = createConsentStore(safeStorage())) {
  const t = messages(doc.documentElement.lang);
  const announce = el('p', { class: 'muted', role: 'status', 'aria-live': 'polite' });

  const notify = (record) => {
    announce.textContent = t.saved;
    doc.dispatchEvent(new CustomEvent('sprelia:consent', { detail: record }));
  };

  // Banner
  const banner = el('section', { class: 'consent-banner', 'aria-label': t.bannerLabel });
  const reject = el('button', { type: 'button', class: 'btn', text: t.rejectAll });
  const accept = el('button', { type: 'button', class: 'btn', text: t.acceptAll });
  const manage = el('button', { type: 'button', class: 'btn btn-primary', text: t.manage });
  banner.append(el('div', { class: 'container' }, [el('p', { text: t.bannerText }), el('div', { class: 'consent-actions' }, [reject, accept, manage])]));

  // Dialog
  const titleId = 'consent-dialog-title';
  const dialog = el('dialog', { class: 'consent-dialog', 'aria-labelledby': titleId });
  const form = el('form', { method: 'dialog' });
  const option = (id, label, text, checked, disabled) => {
    const input = el('input', { type: 'checkbox', id: `consent-${id}`, name: id });
    input.checked = checked;
    input.disabled = disabled;
    return el('div', { class: 'consent-option' }, [
      el('label', { for: `consent-${id}` }, [input, el('span', { text: label })]),
      el('p', { class: 'muted', text }),
    ]);
  };
  const current = () => store.get()?.choices ?? allChoices(false);
  const fill = () => {
    form.replaceChildren(
      el('h2', { id: titleId, text: t.dialogTitle }),
      el('p', { text: t.dialogIntro }),
      option('necessary', t.necessary, t.necessaryText, true, true),
      option('analytics', t.analytics, t.analyticsText, current().analytics, false),
      option('marketing', t.marketing, t.marketingText, current().marketing, false),
      el('div', { class: 'consent-actions' }, [
        el('button', { type: 'submit', class: 'btn btn-primary', value: 'save', text: t.save }),
        el('button', { type: 'submit', class: 'btn', value: 'cancel', text: t.cancel }),
      ]),
    );
  };
  dialog.append(form);

  const decided = (record) => {
    banner.hidden = true;
    notify(record);
  };
  reject.addEventListener('click', () => decided(store.rejectAll()));
  accept.addEventListener('click', () => decided(store.acceptAll()));
  const openPreferences = () => {
    fill();
    if (typeof dialog.showModal === 'function') dialog.showModal();
    else dialog.setAttribute('open', '');
  };
  manage.addEventListener('click', openPreferences);
  dialog.addEventListener('close', () => {
    if (dialog.returnValue !== 'save') return;
    const data = new FormData(form);
    decided(store.save(Object.fromEntries(OPTIONAL_CATEGORIES.map((c) => [c, data.get(c) === 'on']))));
  });

  banner.hidden = !store.needsDecision();
  doc.body.append(banner, dialog, announce);
  for (const button of doc.querySelectorAll('[data-consent-open]')) button.addEventListener('click', openPreferences);

  return { store, openPreferences };
}

if (typeof window !== 'undefined' && typeof document !== 'undefined') {
  const start = () => {
    const ui = initConsentUi();
    // Small read-only API for any future optional feature. Nothing optional is loaded today.
    window.SpreliaConsent = Object.freeze({ get: ui.store.get, has: ui.store.has, open: ui.openPreferences });
  };
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', start);
  else start();
}
