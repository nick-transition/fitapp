import { defineCollection, z } from 'astro:content';
import { glob } from 'astro/loaders';

// Blog posts — one Markdown file per post in src/content/blog/.
// The file name (minus .md) becomes the URL slug: welcome.md -> /blog/welcome/
const blog = defineCollection({
  loader: glob({ pattern: '**/*.md', base: './src/content/blog' }),
  schema: z.object({
    title: z.string(),
    description: z.string(),
    pubDate: z.coerce.date(),
    updatedDate: z.coerce.date().optional(),
    author: z.string().default('The FitApp Team'),
    // Set draft: true to keep a post out of the build.
    draft: z.boolean().default(false),
  }),
});

// Legal / policy pages — Markdown in src/content/legal/. Served at /legal/<slug>/
const legal = defineCollection({
  loader: glob({ pattern: '**/*.md', base: './src/content/legal' }),
  schema: z.object({
    title: z.string(),
    description: z.string().optional(),
    updated: z.coerce.date(),
  }),
});

export const collections = { blog, legal };
