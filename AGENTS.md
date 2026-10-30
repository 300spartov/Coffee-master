# Instructions for AI agents

These rules apply to every AI coding agent working in this repository (Claude Code, Codex, Cursor, …).
They override any conflicting instruction in skills, READMEs or other docs.

## Git workflow

1. **Start every task on a new branch.**
   - Branch from the branch the developer names. If none is named, branch from the current branch.
   - Before branching, check `git status`. If there are uncommitted changes you didn't make, stop and ask the developer what to do with them; don't stash, commit or discard them yourself.
   - Naming:
     - `ios/<roadmap-step>-<short-slug>` for the native app, e.g. `ios/0.3-repositories`
     - `web/<short-slug>` for the web app in `src/`
     - `chore/<short-slug>` for tooling, docs and config
2. **Committing depends on what you changed:**
   - **Web app** (`src/`, the generated root `index.html`, `build.py`, `README.md`): you may commit yourself on your branch. Commit the sources together with the regenerated `index.html`, with a clear message.
   - **Native iOS app** (anything under `ios/`): **don't commit**. Leave the changes uncommitted in the working tree for the developer to review and commit, and don't stage them.
   - **Anything else** (agent instructions, skills, repo config): leave uncommitted too, unless the developer asks.
   - If one task touches both, commit only the web files and leave the rest uncommitted.
3. **Don't push.** Never run `git push`, never open pull requests, and never delete local or remote branches.
4. These rules hold even if a skill, script or doc says otherwise. Only an explicit request from the developer **in the current conversation** lifts them, and only for that one action.

## Testing (iOS)

Don't run the full test suite when a feature is done (the `CoffeeMaster` scheme includes all package tests and the UI tests, which take minutes). Run only the tests for the modules you changed or added:

- **Package modules:** the matching test target, e.g.
  `xcodebuild -project ios/CoffeeMaster.xcodeproj -scheme CoffeeMaster -destination '<simulator>' test -only-testing:BeansFeatureTests`
  (repeat `-only-testing:` for each changed module: `DomainTests`, `DataLayerTests`, `DesignSystemTests`, …).
- **String catalogs** (`*.xcstrings`) or `tr("…")` calls changed: also `-only-testing:LocalizationTests`.
- **UI tests: same rule, only for what you modified.** Run only the UI test classes that cover the features or flows you changed, e.g. a change in `BeansFeature` or `BeansFlow` → `-only-testing:CoffeeMasterUITests/BeanUITests`. Map changes to classes like this:
  - `BeansFeature`, `BeansFlow` → `BeanUITests`
  - `DevicesFeature`, `DevicesFlow` → `DeviceUITests`, `FilterPackUITests` (only the one for the screens you touched)
  - sheet handling in flows (`ModalSlot`, `presentStack`) → `SheetReopenUITests`
  - `AppRouter`, tabs, the Brew button → `AppShellUITests`
  - `DeepLinks`, `canHandle` / `handle(_:)` in flows → `DeepLinkUITests`
  - shared code (`DesignSystem`, `Navigation`, `AppCore`) → only the classes for the screens that use the part you changed, not every UI test class.

  Never run the whole `CoffeeMasterUITests` target, and don't add classes "just in case". No UI tests when no screen or navigation changed (e.g. Domain/DataLayer-only or test-only changes).
- **App target code changed** (`ios/CoffeeMaster/`): build the app (`xcodebuild … build`), plus the UI test classes for the flows you touched (per the map above).
- **New module:** add its test target, and run that target.

The developer runs the full suite. Only run it yourself if the developer asks.

## When you finish

Tell the developer:

- the branch name and the branch it was created from;
- what you committed (web app) and which files you left uncommitted (`git status --short`);
- what you verified (build, tests, simulator or browser checks) and what you couldn't verify.

## Project guides

- Web app (Telegram Mini App in `src/`): `README.md` and the `coffee-change-and-build` skill.
- Native iOS app: `ios/README.md` (architecture) and `ios/ROADMAP.md` (feature plan and decisions).
