# FitApp Marketing Site

A lightweight, static marketing site built with [Astro](https://astro.build).
Content is **Markdown in git** — there is no CMS, no database, no separate service.
To publish, you commit a file and open a PR.

It deploys as a **second Firebase Hosting site** in the same Firebase project as the
Flutter app (`fitapp-ns`). The app stays on `build/web`; this site serves from
`marketing/dist`.

## Local development

```bash
cd marketing
npm install
npm run dev        # http://localhost:4321
```

## Editing content

| To change...        | Edit...                                             |
|---------------------|-----------------------------------------------------|
| Landing page        | `src/pages/index.astro`                             |
| Pricing             | `src/pages/pricing.astro`                           |
| A blog post         | add/edit `src/content/blog/<slug>.md`               |
| Privacy / Terms     | `src/content/legal/privacy.md` / `terms.md`         |
| Site name, nav, URLs| `src/consts.ts`                                      |
| Global styles       | `src/styles/global.css`                             |

### Adding a blog post

Create `src/content/blog/my-post.md`:

```md
---
title: My post title
description: One-sentence summary used for SEO and the post list.
pubDate: 2026-07-10
author: Your Name          # optional
draft: false               # set true to hide from the build
---

Write the post in **Markdown**.
```

It appears automatically at `/blog/my-post/`.

## Build

```bash
npm run build      # outputs static HTML to marketing/dist
npm run preview    # serve the built site locally
```

## Deploy

From the **repo root** (multi-site targets are configured in `.firebaserc`):

```bash
npm --prefix marketing run build
firebase deploy --only hosting:marketing
```

The Flutter app deploys independently with `firebase deploy --only hosting:app`.

### First-time hosting setup

The `marketing` Firebase Hosting site must exist once:

```bash
firebase hosting:sites:create fitapp-ns-marketing
firebase target:apply hosting marketing fitapp-ns-marketing
```

(The `target:apply` mapping is already recorded in `.firebaserc`; the
`sites:create` step is a one-time action on the Firebase project.)
