# Handoff: iOS SwiftUI port of QRinajar

## Where the work is

Two locations, do not confuse them:

1. **Spec**: `~/QRinajar/plan.md` — the authoritative plan for this port. Read it first, in full.
2. **In-progress code**: a git worktree at
   `~/QRinajar/.claude/worktrees/agent-ade44713eee6a8646`
   (branch `worktree-agent-ade44713eee6a8646`), *not* the main `~/QRinajar` checkout.
   A prior agent was implementing the plan there and was stopped mid-task (killed by
   the user for taking too long / going quiet on status, not because of a blocking
   error). Its `ios/` tree is real, partially built, and worth continuing rather than
   restarting from scratch.

To continue: either `cd` into that worktree directly, or merge/cherry-pick its
`ios/` tree into the main repo — your call, but check `git log`/`git diff` in the
worktree first so you know exactly what it changed before merging anything.

## What's already done in the worktree

Non-build files present under `ios/QRinajar/`:

```
App/QRinajarApp.swift
App/RootTabView.swift
Assets.xcassets/ (AccentColor, AppIcon from assets/logo.png)
Info.plist
Model/QRDesign.swift
Model/PresetStore.swift
Model/PayloadBuilder.swift
Rendering/QRCardRenderer.swift
Rendering/ScanTester.swift
Views/ColorHex.swift
Views/Controls.swift
Views/CreateView.swift
Views/StyleView.swift
Views/ExportView.swift
Views/LibraryView.swift
Views/PreviewCard.swift
project.yml (XcodeGen was available and used)
QRinajar.xcodeproj/ (generated via XcodeGen from project.yml)
screenshots/create-{light,dark}.png, style-{light,dark}.png,
            export-{light,dark}.png, library-{light,dark}.png
```

So: **all the files the plan calls for exist**, the Xcode project was generated
with XcodeGen, the QRCode SPM package resolved and built (there's a populated
`build/` derived-data directory with a compiled `QRCode` package target), and a
full simulator screenshot pass was taken across all 4 tabs × light/dark.

## Known issue — screenshots are mislabeled, unverified

The agent's last message before being stopped:

> "Screenshots render beautifully, but there's an off-by-one: the file labeled
> create-light actually shows Style, and style-dark shows Export — the
> `terminate` is async so each launch reused the prior process. Let me recapture
> with a settle delay and verify."

So the screenshot *filenames* in `ios/QRinajar/screenshots/` are shifted by one
tab relative to their actual content — the capture script terminated the
simulator app and relaunched too quickly, so an old process was still on screen
when the next screenshot fired. **Do not trust the screenshot filenames as-is.**
First task: fix the capture script (add a settle delay / wait for
`simctl launch` to actually present the new view before screenshotting, or
poll for the process pid to change) and recapture all 8 images correctly.

## Not yet confirmed

- Whether `xcodebuild ... build` was run to a clean **success** end-to-end after
  all files landed, or whether the last known-good build predates some of the
  later view files. Rerun the build first thing:
  ```
  xcodebuild -project ios/QRinajar/QRinajar.xcodeproj -scheme QRinajar \
    -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build
  ```
  Fix any errors before doing anything else.
- Functional smoke checks from the plan's Verification section were not
  confirmed complete: style-control → preview live update, PNG/SVG export
  validity, scan self-test decode correctness, preset save/load round-trip.
- No commit was made in the worktree (verify with `git status` /
  `git log --oneline` — don't assume either way).

## Suggested next steps, in order

1. `cd ~/QRinajar/.claude/worktrees/agent-ade44713eee6a8646 && git status && git log --oneline` —
   see exactly what's committed vs. dirty before touching anything.
2. Run the `xcodebuild` command above; fix any compile errors.
3. Fix the screenshot capture timing bug and recapture all 8 screenshots
   (4 tabs × light/dark) with correct labeling; visually confirm each one
   matches its filename.
4. Run the functional smoke checks listed in `plan.md`'s Verification section.
5. Diff the worktree's `ios/` tree against plan.md's file list one more time to
   confirm nothing was stubbed or skipped, then merge into the main branch.

## Do not

- Don't discard the worktree — it has a working Xcode project with the SPM
  dependency already resolved, which is the slowest/most error-prone part to
  redo.
- Don't trust "it works" claims about the screenshots without opening the PNGs —
  the agent itself flagged them as currently mislabeled/unverified.
