# Handoff: iOS app status

Last updated: 2026-07-20 (evening). Everything described here is merged into `master`
and pushed to `origin/master` — there is no outstanding worktree or branch
to reconcile. `git log --oneline -20` from repo root will show the recent
history if you want the blow-by-blow.

## Where things live

- `ios/QRinajar/` — the whole native app. `project.yml` is the source of
  truth for the Xcode project; regenerate with `xcodegen generate` after
  adding/removing/renaming any Swift file (see AGENTS.md for the full
  command).
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
4. **Share** (`.export`) — title is literally "Share" (`FlowStep.title`),
   not "Save & export"/"Save & Share" as in earlier iterations. The
   footer's floating pill (labeled "FINISH") opens a
   `.confirmationDialog` with Save and Share options: Save opens the same
   "Save to Library" name-prompt alert used when backing out of Style
   with unsaved changes (`showSaveAlert`/`saveName`, pre-filled with
   `defaultName()`), stores it via `PresetStore.save`, and shows a brief
   "Added to Library" toast (`showSavedToast()`, bottom-center, ~1.8s)
   instead of jumping to the Library — Share builds a `ShareItem` and
   presents the **native iOS share sheet**
   (`UIActivityViewController` via `ActivityShareSheet` in
   `Views/ExportView.swift`) — its built-in Copy/Save Image/AirDrop/Print
   actions replaced a custom Copy/Save/Share picker that used to live
   here. `ShareItem` (the `Identifiable` image wrapper) and
   `ActivityShareSheet` are both `internal`, not `private`, specifically
   so `LibraryView`'s QR popup can reuse them too. Below the preview, a
   large "Start Another" button (`plus.circle.fill`) resets `design` to
   `.factory` and pops `path` back to the first step — it always confirms
   first via an alert (`showStartAnotherAlert`) since it's destructive to
   whatever's on screen and unsaved. The PNG/JPEG/SVG ShareLink row and
   the in-app "scan self-test" button were both removed further back —
   ask before re-adding either without reading the "known issues" section
   below.

The footer CTA (Next / Share) is a floating pill
(`FloatingPillButtonStyle` in `Views/Controls.swift`) — solid `brandBlue`,
16pt corner radius (matches the Style step's preset cards), soft glow
shadow, inset from the screen edges rather than a full-bleed bar. Saving
the current design to the Library now only happens from the "Unsaved
style changes" prompt when backing out of the Style step with unsaved
edits — there's no standalone "save to library" affordance on the Share
step anymore.

All four steps are pushed onto a real `NavigationStack` (see
`CreateFlowView.body`, `path: [FlowStep]`), not swapped via `@State` in
place — that's deliberate, it's what makes the system's edge-swipe-back
gesture work for free.

Persistent across every step (via `.overlay` in `FlowStepView`):
- A floating **scanner button** (bottom-trailing) — `Views/QRScanner.swift`.
  Explains the camera permission before requesting it, decodes via
  AVFoundation, opens the result in Safari, fires a success haptic.
- Toolbar **appearance toggle** and **tray** (Library) icons, top-trailing,
  auto-grouped into one glass pill by the system. The appearance icon
  shows sun in dark mode / moon in light mode (the mode a tap moves
  *toward*) and switches directly — there is no Settings screen anymore;
  `SettingsView.swift` was deleted. Tapping sets `AppColorSchemeStorage`
  straight to the opposite of `colorScheme`, so "Follow System" is only
  reachable by actually matching the device's own appearance, not from
  this button.

On cold launch: `SplashScreenView` (~2.4s, skipped when
`QRINAJAR_TAB`/`QRINAJAR_SELFTEST` env vars are set) → first-run only,
`WelcomeView` (explains the app, lets you pick light/dark/system) →
`RootTabView` → `CreateFlowView`.

### Error correction (Enter details step)

`ECCThermometer` in `Views/ContentDataForm.swift` replaced the old
sheet-based ECC picker: an inline 4-stop L/M/Q/H bar directly under the
live preview, filling toward the selected level, plus `RecoveryVisual` — a
small mock module grid with a blue "damage patch" sized (and exaggerated
~2.2x for legibility) to that level's real recovery percentage. Copy is
deliberately framed around what can be *missing, dirty, or covered by a
logo*, not abstract "tolerance." The patch has a continuous gentle
breathing pulse (`pulse` state, `repeatForever` scale animation) plus a
quick bump (`bump` state) whenever the selected level changes
(`.onChange(of: percent)`), so the illustration draws the eye rather than
sitting static. A `brandBlue` bracket (`LogoBracketShape`, an "⊔"-style
under-brace) spans the Q and H columns of the thermometer with a "Best
for logos" label beneath — those are the two levels actually worth
choosing for a center logo, per the info tip copy; L/M are correct QR
spec levels too (ISO/IEC 18004), not placeholders.

### Library (`Views/LibraryView.swift`)

Rewritten from a plain `List` with native `.swipeActions` to a
custom-drawn `LibraryRow` because the native API can't be driven
programmatically (needed for the first-time swipe demo) and can't do a
full swipe-through delete with velocity:

- No inline delete/rename buttons and no trailing chevron — a preset row
  shows name/date and a QR icon (opens `QRPopupCard`). Left swipe reveals
  delete (red); right swipe reveals rename (blue, `pencil` icon), which
  opens a `.alert` with a `TextField` wired to `PresetStore.rename`.
  Both reveals share the same underlying mechanics via a signed `offset`,
  and both color backings extend to the true edges of the row —
  `listRowInsets` is zero, with the row's own text content getting its
  16pt margin from padding inside the row instead, so the reveal isn't
  inset from the row's edge the way the old layout had it.
- Swiping reveals a backing whose opacity is gated by `revealAmount` /
  `editRevealAmount` (zero at rest — it never bleeds outside the reveal)
  via `simultaneousGesture` (not `.gesture`) so the drag isn't delayed
  behind the row's own tap recognizer. **Delete only commits on a
  genuinely completed swipe with inertia** — `predictedEndTranslation`
  (which folds in velocity) has to carry past 85% of the row's width
  (`fullSwipeThreshold`); a slow drag that merely crosses the reveal
  threshold and stops does not delete, it just reveals the button.
  Rename's full-swipe-through still commits at the halfway point (no
  inertia requirement) since it isn't destructive. A drag that stops
  short of committing snaps to whichever state (open/closed) it's
  numerically closer to, computed from the row's *absolute* position
  (`dragStartOffset + translation`, captured once per gesture via an
  `isDragging` flag) rather than the raw per-gesture translation — the
  earlier version recomputed from zero on every new drag, so a second
  half-hearted tug on an already-open row could snap it shut even though
  nothing was actually being undone. A revealed row now only closes via
  an explicit tap on the row (treated as "tapping off" it, handled in
  `handleContentTap`) or by dragging it back — never automatically.
- **Shake to undo** (delete only): `Views/ShakeDetector.swift` bridges
  UIKit's `motionEnded`/`.motionShake` (there's no SwiftUI shake gesture)
  to a `NotificationCenter` post and a `View.onShake { }` modifier.
  `LibraryView` keeps the last-deleted preset + its original index for 8
  seconds (`DispatchWorkItem`, cancelled/replaced on each new delete) and
  restores it via `PresetStore.restore(_:at:)` on shake.
  `PresetStore.restore` (added alongside `save`/`delete`) re-inserts at a
  clamped index rather than always prepending, so undo puts a row back
  where it was.
- Only the first row plays a scripted peek-and-return demo — delete
  first, then rename. It's guaranteed the very first time the Library is
  ever opened (`AppStorage("librarySwipeDemoLastShown") == 0`), then only
  reappears as an occasional reminder if 14+ days have passed since it
  last played — no repeat-visit counter, no "turn off tips?" prompt, just
  a quiet, infrequent nudge.
- Tapping a row's QR icon opens `QRPopupCard` — a bottom-anchored card
  over a dimmed scrim, flush against the bottom safe area (top corners
  only rounded via `.rect(topLeadingRadius:topTrailingRadius:)`), with its
  own Share button. Tapping the scrim dismisses it.
- The Library's own `.sheet` presentation has `.interactiveDismissDisabled()`
  set (in `CreateFlowView`) — without it, a diagonal or imprecise row
  swipe could get partly read by iOS as a downward drag-to-dismiss on the
  sheet itself, closing the whole Library. The toolbar X button is the
  only way to dismiss it now — it does **not** have `GlassButtonStyle`
  applied (that modifier is only for standalone controls; a `ToolbarItem`
  already gets Liquid Glass automatically, and stacking both drew two
  overlapping glass shapes).
- "Save current design" and "Reset to factory" were removed from the
  Library menu — saving now only happens from the Share step's FINISH
  dialog, which no longer auto-navigates to the Library on save (see
  Share step above) — it shows a toast instead.

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

## App Store distribution status

**Submitted for review** as of 2026-07-19 (iOS version 1.0, build 1,
Universal Purchase covering iOS + macOS via Mac Catalyst). If it comes
back approved, there's nothing left to do here. If it's rejected, Apple's
rejection message in App Store Connect → Resolution Center will say why —
common first-submission issues are metadata mismatches or screenshot
inaccuracies, neither of which should apply since everything was filled
in carefully, but read the actual rejection reason before assuming.

Relevant project config for this submission:

- `DEVELOPMENT_TEAM` is set in `project.yml` (a Developer Program Team ID —
  not personal info, just an account identifier; required for
  `CODE_SIGN_STYLE: Automatic` to resolve a signing identity/provisioning
  profile). Whoever continues this needs Xcode signed into an Apple ID
  that's a member of that team (Xcode → Settings → Accounts) before
  archiving will work.
- `SUPPORTS_MACCATALYST: YES` + `DERIVE_MACCATALYST_PRODUCT_BUNDLE_IDENTIFIER: NO`
  means the same binary ships on macOS too, under the same bundle ID —
  set up as a single Universal Purchase (one App Store Connect app record,
  both iOS and macOS platforms checked) rather than two separate listings.
- `UIRequiresFullScreen: true` — the app doesn't support iPad Split View;
  this was required by App Store validation since `TARGETED_DEVICE_FAMILY`
  includes iPad but the app only supports 3 of 4 orientations.
- `LSApplicationCategoryType: public.app-category.utilities` — required
  for the Mac Catalyst build; App Store Connect otherwise rejects it.
- `PRIVACY.md` at repo root is the app's privacy policy (required by App
  Store Connect before submission) — accurate, since the app collects
  nothing. Its GitHub URL (`.../blob/master/PRIVACY.md`) is what's entered
  as the Privacy Policy URL in App Privacy.
- The app icon shown on the App Store listing is auto-extracted from the
  uploaded build's `AppIcon.icon` asset — no separate manual upload exists
  in current App Store Connect, despite older guidance suggesting one.
- Marketing screenshots were captured from Simulator at exact required
  pixel sizes: iPhone 6.9" needs `1320×2868` (matches iPhone 17 Pro Max
  natively), iPhone 6.5" needs exactly `1242×2688` (no current Simulator
  device is that size — the 1320×2868 captures were downscaled with
  `sips -z 2688 1242` to hit it), 13" iPad needs `2064×2752` (matches iPad
  Pro 13-inch natively).

Screenshots themselves were never committed to the repo — generated into
`/tmp/appstore_screenshots/`, uploaded directly to App Store Connect, and
left out of git deliberately since they're one-off marketing assets, not
project source.

App Review contact information (account holder's name/phone/email) was
filled in directly in App Store Connect — intentionally not recorded here
or anywhere in the repo.

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
