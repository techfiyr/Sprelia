import { readdirSync, readFileSync, statSync } from 'node:fs';
import { join, relative } from 'node:path';
import { fileURLToPath } from 'node:url';
import { describe, expect, it } from 'vitest';

/**
 * Branding regression check (backend + website): the user-facing name is "Hermione".
 * AI prompts (what tutors say), API messages and the published website must never use the
 * old product name. Technical identifiers (`speakdaily-backend` package name, repository
 * folder) are not user-facing and are not scanned.
 */
const STALE = /speaks?[\s_-]?daily/i;
const root = fileURLToPath(new URL('..', import.meta.url));
const walk = (dir: string): string[] =>
  readdirSync(dir).flatMap((f) => (statSync(join(dir, f)).isDirectory() ? walk(join(dir, f)) : [join(dir, f)]));

const hits = (files: string[]) =>
  files.flatMap((f) =>
    readFileSync(f, 'utf8')
      .split('\n')
      .flatMap((line, i) => (STALE.test(line) ? [`${relative(root, f)}:${i + 1}`] : [])),
  );

describe('branding', () => {
  it('backend source (AI prompts, API messages, logs) never uses the old name', () => {
    const files = walk(join(root, 'src')).filter((f) => f.endsWith('.ts'));
    expect(files.length).toBeGreaterThan(10);
    expect(hits(files)).toEqual([]);
  });

  it('the Netlify function and website never use the old name, and say Hermione', () => {
    const files = [...walk(join(root, 'netlify'))].filter((f) => /\.(m?ts|html|js|css|txt)$/.test(f));
    expect(hits(files)).toEqual([]);
    for (const page of files.filter((f) => f.endsWith('.html'))) {
      expect(readFileSync(page, 'utf8'), relative(root, page)).toMatch(/<title>[^<]*Hermione[^<]*<\/title>/);
    }
  });
});
