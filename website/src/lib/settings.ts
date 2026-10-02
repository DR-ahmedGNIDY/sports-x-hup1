/// The links and contact details the admin edits under "Website settings"
/// in the app's dashboard (`GET /site-settings`). Same shape as the API.
export interface SiteSettings {
  facebookUrl: string;
  instagramUrl: string;
  xUrl: string;
  tiktokUrl: string;
  youtubeUrl: string;
  whatsappNumber: string;
  phones: { label: string; number: string }[];
  email: string;
  googlePlayUrl: string;
  webAppUrl: string;
}

export const API_BASE_URL = (
  import.meta.env.PUBLIC_API_BASE_URL ?? 'https://api.sportxhup.com'
).replace(/\/$/, '');

export const APP_URL = (
  import.meta.env.PUBLIC_APP_URL ?? 'https://app.sportxhup.com'
).replace(/\/$/, '');

const EMPTY: SiteSettings = {
  facebookUrl: '',
  instagramUrl: '',
  xUrl: '',
  tiktokUrl: '',
  youtubeUrl: '',
  whatsappNumber: '',
  phones: [],
  email: '',
  googlePlayUrl: '',
  webAppUrl: '',
};

let cached: Promise<SiteSettings> | undefined;

/// Read once per build. A build must not fail because the API is briefly
/// down: it falls back to empty settings (every item hidden), and the
/// in-page refresh in `Base.astro` fills them in on the visitor's side.
export function loadSettings(): Promise<SiteSettings> {
  cached ??= fetch(`${API_BASE_URL}/site-settings`)
    .then((r) => (r.ok ? r.json() : EMPTY))
    .then((json) => ({ ...EMPTY, ...json }))
    .catch(() => EMPTY);
  return cached;
}

/// `wa.me` wants digits only, no plus and no spaces.
export const whatsappLink = (number: string) =>
  `https://wa.me/${number.replace(/[^0-9]/g, '')}`;

export const telLink = (number: string) =>
  `tel:${number.replace(/[^0-9+]/g, '')}`;

/// The web version the iOS card opens: the admin's value when set, else the
/// app domain this site is deployed beside.
export const webAppUrl = (s: SiteSettings) => s.webAppUrl || APP_URL;
