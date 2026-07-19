# Handoff: iOS app status

Last updated: 2026-07-19. Everything described here is merged into `master`
and pushed to `origin/master` — there is no outstanding worktree or branch
to reconcile. `git log --oneline -20` from repo root will show the recent
history if you want the blow-by-blow.

## Where things live

- `ios/QRinajar/` — the whole native app. `project.yml` is the source of
  truth for the Xcode project; regenerate with `xcodegen generate` after
  adding/removing/renaming any Swift file (see AGENTS.md for the full
  command).
- `plan.md` — the **original** implementation plan. It describes a
  tab-bar architecture that has since been replaced by a guided
  step-by-step flow (see below). Treat it as historical context for *why*
  files are named/shaped the way they are, not as a description of the
  current UI.
- `README.md` — has a full "iOS app" section kept in sync with what's
  actually shipped; check there first for a feature-level summary before
  reading code.

## Current architecture (as of this handoff)

The app is **one linear flow**, not a tab bar:

1. **What are you sharing?** (`FlowStep.type`) — `ContentTypePicker` in
   `Views/CreateFlowView.swift`, a 2-column bubble grid (Website, Wi-Fi,
   Contact, Social, Custom text last). Tapping a bubble auto-advances —
   there's no separate Next button on this step.
2. **Enter the details** (`.data`) — `Views/ContentDataForm.swift`,
   type-specific fields + error correction picker.
3. **Style it** (`.style`) — `Views/StyleView.swift`. Only the
   Square/Rounded/Custom preset row shows by default; `StyleCustomPanels`
   (the full fine-tune controls) only renders once Custom is tapped
   (tracked by `FlowStepView.showCustomPanels` in CreateFlowView.swift,
   not by QRDesign itself). Backing out of this step with unsaved changes
   (compared against a snapshot captured on `.onAppear`) prompts to save,
   discard, or keep editing before the pop is allowed to complete.
4. **Save & export** (`.export`) — `Views/ExportView.swift`. Just
   **Save to Photos** and **Copy**, both large rounded-square glass
   buttons. The PNG/JPEG/SVG ShareLink row and the in-app "scan self-test"
   button were both removed — ask before re-adding either without reading
   the "known issues" section below.

All four steps are pushed onto a real `NavigationStack` (see
`CreateFlowView.body`, `path: [FlowStep]`), not swapped via `@State` in
place — that's deliberate, it's what makes the system's edge-swipe-back
gesture work for free.

Persistent across every step (via `.overlay` in `FlowStepView`):
- A floating **scanner button** (bottom-trailing) — `Views/QRScanner.swift`.
  Explains the camera permission before requesting it, decodes via
  AVFoundation, opens the result in Safari, fires a success haptic.
- Toolbar **gear** (Settings — light/dark/system) and **tray** (Library)
  icons, top-trailing, auto-grouped into one glass pill by the system.

On cold launch: `SplashScreenView` (~2.4s, skipped when
`QRINAJAR_TAB`/`QRINAJAR_SELFTEST` env vars are set) → first-run only,
`WelcomeView` (explains the app, lets you pick light/dark/system) →
`RootTabView` → `CreateFlowView`.

## Known issues / deliberately untested paths

- **Camera scanner**: the Simulator has no camera hardware, so the live
  AVFoundation feed has never actually been visually verified — only that
  it compiles and the permission/UI plumbing around it (explainer alert →
  system prompt → Settings deep-link on denial) is wired correctly. Test
  on a real device before trusting it fully.
- **Scan self-test was removed** (previously in Export) because Vision's
  `VNDetectBarcodesRequest` gave inconsistent results in the Simulator —
  confirmed via `zbarimg` that the *rendered* QR codes were actually valid
  and scannable, so the removal was about Vision's reliability, not a bug
  in `Rendering/QRCardRenderer.swift`. The decode logic still exists
  (`Rendering/ScanTester.swift`) and is used by the internal `SelfTest`
  dev tool (`App/SelfTest.swift`, triggered by `QRINAJAR_SELFTEST=1`) —
  don't delete it, just don't wire it back into user-facing UI without
  a better decoder or real-device testing.
- **No accessibility/tap automation** was available in the environment
  this was built in (no `idb`/`cliclick`-driven Simulator taps beyond what
  `xcrun simctl` itself supports, and no Accessibility permission for
  `osascript`/System Events). Anything gated behind a sheet or modal that
  needed an actual tap to reach (Library's delete-confirmation alert,
  onboarding step 2, Settings toggle) was verified by code review + a
  clean build rather than a screenshot. If you get real tap automation
  working, it'd be worth spot-checking those.
- `ios/QRinajar/screenshots/` is gitignored and untracked as of this
  handoff (still generated locally by `capture_screenshots.sh` for manual
  review, just not committed).

## Verification commands

```
cd ios/QRinajar && xcodegen generate   # after any file add/remove/rename
cd ../..
xcodebuild -project ios/QRinajar/QRinajar.xcodeproj -scheme QRinajar \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

Simulator device name may need adjusting — `xcrun simctl list devices` to
see what's actually available; `iPhone 16 Pro` wasn't present on the
machine this was built on, `iPhone 17 Pro` was used instead throughout.

Headless functional checks (style apply, PNG/SVG export validity, preset
round-trip, scan decode) live in `App/SelfTest.swift`, run via:

```
xcrun simctl launch --console <device> com.qrinajar.app
# with SIMCTL_CHILD_QRINAJAR_SELFTEST=1 set in the environment
```
