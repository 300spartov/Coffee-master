---
name: coffee-change-and-build
description: How to make changes in the Coffee-master app (src/ feature folders) and rebuild the root index.html with build.py. Use when adding or editing a screen, feature, HTML partial, JS or CSS file in this project, or when asked to build or regenerate index.html.
---

# Making changes in Coffee-master and building it

The app is a static Telegram Mini App with no framework and no bundler. The sources live in `src/`. The root `index.html` is **generated** by `build.py`; users open it by double-clicking it (`file://`), and Vercel deploys it.

## Layout

```
src/index.html        page template: <head>, <link> CSS in cascade order, .app frame,
                      <div data-include="..."> placeholders, <script src> in load order
src/core/             shared code: i18n, data/DB, state S + save(), utils, overlays,
                      router (showScr), autocomplete, Supabase sync, boot.js (startup, loaded LAST)
src/features/<name>/  one screen/feature: <name>.html, <name>.css, <name>.js (may have sub-folders, e.g. brew/setup/)
build.py              inlines the HTML partials into the root index.html
index.html            GENERATED. Never edit it by hand: the next build overwrites it.
```

## Rules

1. **Edit only files in `src/`** (plus `build.py` / `README.md` when needed).
2. **Changed any `.html` in `src/`** → run `python3 build.py` and commit the regenerated `index.html` together with the source change.
3. **Changes to `.js` / `.css`** take effect without a build, because the page loads them as separate files. Rebuild only if `src/index.html` or a partial changed.
4. **New JS file**: add `<script src="src/...">` to `src/index.html`.
   - Order matters. All files share one global scope: there are no modules, and inline `onclick="fn()"` handlers call globals.
   - Place the new file after the files it uses at load time. `src/core/boot.js` must stay the **last** script.
   - Top-level code must only *define* things (functions, `var`/`let`/`const` with simple values). Anything that runs at startup and calls functions from other files (rendering, reading `S`, init) goes into `src/core/boot.js`. Function declarations are not hoisted across files.
   - Don't redeclare a `let`/`const` name that another file already declares; this throws a SyntaxError at load.
5. **New CSS file**: add `<link rel="stylesheet" href="src/...">` to `src/index.html`. The link order reproduces the original cascade, so put the new link after the stylesheets it overrides, and don't reorder existing links.
6. **New HTML partial**: put `<div data-include="src/features/<name>/<file>.html"></div>` **alone on its own line** (indentation is allowed) where the markup belongs.
   - This goes in `src/index.html` or inside another partial; nesting works.
   - The path is relative to the project root.
   - Partials must be balanced HTML.
   - Screens go inside `.screens`, as `<div class="scr" id="scr-...">`; overlays use `<div class="overlay" id="ov-...">`.
7. Don't "fix" the stray `<div class="cp-card">` in `src/index.html` near `</div><!-- /screens -->`. It keeps the nav inside `.screens`, exactly as the original layout did.
8. Keep the existing style: plain ES5/ES2017 globals, compact code, Ukrainian comments/UI strings, `t('key')` / `data-i18n` for translations (keys in `src/core/i18n.js`).

## New feature checklist

1. Create `src/features/<name>/` with `<name>.html`, `<name>.css` and `<name>.js`, as needed.
2. Wire them into `src/index.html`: the include line, the `<link>`, and the `<script src>` before `src/core/boot.js`.
3. To reach a new screen, use `showScr('scr-<name>')`, defined in `src/core/router.js`. Add a nav button if required.
4. If it needs startup work, call it from `src/core/boot.js`.
5. Build and verify (below).

## Build and verify

```bash
python3 build.py                              # prints "index.html зібрано (N KB)"
grep -c 'data-include' index.html             # must print 0 (all partials inlined)
```

- `build.py` exits with an error if an include path is missing or the includes form a cycle. Fix the path and rerun.
- Smoke-test by opening `index.html` directly (`open index.html` on macOS) and checking the browser console for errors. If headless Chrome is available, load it via `file://` and confirm there are no `pageerror` events while switching screens.
- Commit the source changes and the regenerated `index.html` together, on a new branch (see `AGENTS.md`). Don't push.
