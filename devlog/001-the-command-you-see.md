# Devlog 001 — The command you see is the command that runs

*June 2026*

Every GUI over a command-line tool faces the same fork in the road: hide the tool, or expose it. Hide it and you get approachability with a glass ceiling — the moment something fails, your user is debugging *your* abstraction instead of the actual error. Expose it raw and you've built a syntax editor with extra steps.

FFmix's founding decision is a third path, stated as a contract: **every command string shown in the UI is the literal string handed to the engine.** Not a simplified rendering. Not a preview that gets "fixed up" at execution time. The string in the "Advanced" section of every task drawer is the `argv`.

## What this costs

This contract is expensive, which is probably why it's rare. Three examples of what it forbids:

**No silent fixes.** Our embedded engine is LGPL — no x264. When a recipe written for `libx264 -crf 23` runs against it, we *must* rewrite to `h264_videotoolbox -q:v 58`. The tempting design: show the pretty canonical command, swap in the real one at run time. Forbidden. The adaptation happens *before* display, so what you read is what executes — and if you copy it to your terminal against the same binary, you get the same result.

**No "the GUI knows better".** Manual mode lets you edit the raw command. The moment you touch it, every GUI control locks (greyed, hit-testing off) — because the controls can no longer claim to describe what will run. The text field is now the single source of truth. An amber bar offers to restore GUI control, which regenerates the command visibly.

**Two-pass had to become real.** The prototype showed a `-pass 2` command and ran a simulation. Shipping honestly meant actually running pass 1 (`-an -f null /dev/null`, progress 0–50%) then pass 2 (50–100%), with a private `-passlogfile` per job so parallel jobs don't corrupt each other's stats. The displayed command shows the canonical pass-2 form; the engine README documents the expansion. This is the hardest edge of the contract and we keep finding burrs on it.

## What it buys

Trust that compounds. "Your files never leave your Mac" is a claim every app makes; a visible command line with local paths and a local binary is *evidence*. Users who don't read the commands still benefit from the discipline it imposes on us: there is no place in the architecture for behavior the user can't see.

And an unexpected bonus: FFmix turns out to be an ffmpeg *tutor*. Move the quality slider, watch `-crf` change. Pick "keep pitch", see `atempo` appear instead of `asetrate`. Several of our beta testers' most-used feature is the copy button next to the command.

## The test we apply

Every new feature gets the question: *does the displayed command still tell the whole truth?* If a feature needs hidden flags to feel good, the feature is redesigned, not the contract.

Next entry: how we pause an encoder that has no pause button (the kernel had the answer all along).

---

*FFmix is a native macOS frontend for ffmpeg, launching in 2026 — [repo home](../README.md) · [ffmix.com](https://ffmix.com). Commands we generate, with their traps documented: [ffmpeg recipes](../docs/ffmpeg-recipes.md).*
