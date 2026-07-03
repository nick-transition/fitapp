// Central site configuration. Edit these values instead of hunting through
// components — they drive SEO tags, the sitemap, nav, and footer.

// The canonical marketing domain. Update this once the real domain is live
// (e.g. https://www.fitapp.com). For now it points at a placeholder.
export const SITE_URL = 'https://www.fitapp.com';

export const SITE_TITLE = 'FitApp';
export const SITE_TAGLINE = 'Coaching that actually connects.';
export const SITE_DESCRIPTION =
  'FitApp connects athletes and coaches through structured workout programs, ' +
  'per-set session tracking, and inline video references.';

// Where the "Open the app" / "Sign in" buttons point (the Flutter web app).
export const APP_URL = 'https://fitapp.web.app';

export const NAV_LINKS = [
  { href: '/', label: 'Home' },
  { href: '/pricing/', label: 'Pricing' },
  { href: '/blog/', label: 'Blog' },
];

export const FOOTER_LINKS = [
  { href: '/legal/privacy/', label: 'Privacy' },
  { href: '/legal/terms/', label: 'Terms' },
  { href: 'https://github.com/nick-transition/fitapp', label: 'GitHub' },
];
