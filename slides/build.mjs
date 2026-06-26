// Render every numbered Marp deck in this folder to ./out/<name>.<ext>.
//
// Uses only Node built-ins + the pinned @marp-team/marp-cli (OSS, MIT). It spawns the
// locally installed `marp` binary per deck so it is decoupled from the CLI's JS API and
// works identically on Linux (Codespaces / dev container) and Windows.
//
//   node build.mjs            # -> HTML (default; no browser required)
//   node build.mjs html|pdf|pptx
//
// HTML output is headless. PDF/PPTX require a local Chrome/Chromium (see slides/README.md).
import { readdirSync, mkdirSync, existsSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';
import { spawnSync } from 'node:child_process';

const here = dirname(fileURLToPath(import.meta.url));
const format = (process.argv[2] ?? 'html').toLowerCase();

const extraFlags = { html: [], pdf: ['--pdf'], pptx: ['--pptx'] };
if (!(format in extraFlags)) {
  console.error(`Unknown format "${format}". Use one of: html, pdf, pptx.`);
  process.exit(1);
}
const ext = format === 'html' ? 'html' : format;

// Invoke the CLI's JS entry directly with the current Node binary. This is fully
// cross-platform: it sidesteps the OS-specific .cmd/.sh shims in node_modules/.bin and
// tolerates spaces in paths (each argument is passed as a separate array element).
const cliEntry = join(here, 'node_modules', '@marp-team', 'marp-cli', 'marp-cli.js');
if (!existsSync(cliEntry)) {
  console.error('Marp CLI not found. Run "npm install" in slides/ first.');
  process.exit(1);
}

const outDir = join(here, 'out');
mkdirSync(outDir, { recursive: true });

const decks = readdirSync(here)
  .filter((file) => /^\d{2}-.+\.md$/.test(file))
  .sort();

if (decks.length === 0) {
  console.error('No decks found (expected NN-*.md files in slides/).');
  process.exit(1);
}

let failures = 0;
for (const deck of decks) {
  const outName = deck.replace(/\.md$/, `.${ext}`);
  const result = spawnSync(
    process.execPath,
    [cliEntry, '--theme-set', join(here, 'themes'), '--html', ...extraFlags[format], join(here, deck), '-o', join(outDir, outName)],
    { stdio: 'inherit' },
  );
  if (result.status === 0) {
    console.log(`OK   ${deck} -> out/${outName}`);
  } else {
    failures += 1;
    console.error(`FAIL ${deck} (exit ${result.status ?? 'signal'})`);
  }
}

console.log(`\n${decks.length - failures}/${decks.length} deck(s) rendered to slides/out/`);
process.exit(failures ? 1 : 0);
