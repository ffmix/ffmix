# How FFmix works

FFmix is a **translation layer** over ffmpeg, not a wrapper that hides it. This document explains the architecture end to end: how a drag-and-drop or a sentence becomes a reviewed, local ffmpeg process.

```
┌─────────────────────────────── Your Mac ───────────────────────────────┐
│                                                                        │
│  Drop files ──► Probe (AVFoundation) ──► Pick task / describe it       │
│                                              │                         │
│                  ┌───────────────────────────┴──────────────┐          │
│                  ▼                                          ▼          │
│        Task drawer (GUI controls)              AI sentence parsing     │
│                  │                          local intent? ──► template │
│                  │                          compound? ──► API (text    │
│                  │                                         only) ──┐   │
│                  ▼                                                 ▼   │
│        ┌──────────────────────────────────────────────────────────┐   │
│        │  COMMAND LAYER — the literal ffmpeg command, always      │   │
│        │  visible, editable, copyable. Shown == run.              │   │
│        └────────────────────────────┬─────────────────────────────┘   │
│                                     ▼   (user confirms)               │
│        Queue ──► ffmpeg subprocess (-progress pipe:2) ──► Result       │
│                  pause = SIGSTOP · resume = SIGCONT                    │
│                  output next to source, never overwrites               │
└────────────────────────────────────────────────────────────────────────┘
                                     ▲
                 The ONLY thing that ever crosses the network:
                 one sentence of text (optional AI feature). Never a file.
```

## 1. The command layer is the product

Every task drawer (compress, GIF, concat, watermark, speed, rotate, subtitles, …) is a set of GUI controls bound to a **command builder**. As you move a slider, the command string updates live. That string is not documentation — it is the exact `argv` handed to the engine.

This single decision drives everything else:

- **Debuggability.** When a job fails, you can see and copy the real command and the real stderr log. No black box.
- **Trust.** "Local processing" is verifiable: the command names your local file paths and a local binary.
- **Education.** FFmix doubles as the fastest ffmpeg tutor — every interaction shows you the flag it maps to.
- **An escape hatch.** Manual mode locks the GUI controls and runs whatever you type. Power users are never fenced in.

The discipline this requires: the GUI may never "improve" a command behind your back. When the engine *must* adapt a command (see §4), the adapted form is what's displayed.

## 2. Engine resolution — bring your own ffmpeg, or one click

FFmix does not assume how you got ffmpeg. At startup it resolves an engine in order:

1. A path you picked yourself (persisted)
2. FFmix's own managed copy (`~/Library/Application Support/FFmix/engine/ffmpeg`)
3. Homebrew (`/opt/homebrew/bin`, `/usr/local/bin`)
4. `$PATH`

If nothing is found, one click downloads our [reproducible LGPL static build](../engine/) into FFmix's own folder — no terminal, no Homebrew, nothing touches your system environment. The manifest provides a sha256; the binary is verified before first run.

## 3. Capability probing — ffmpeg builds are not interchangeable

A hard-won lesson: **"ffmpeg is installed" tells you almost nothing.** The Homebrew default build (8.x) ships *without* libass or freetype — no `subtitles`, no `drawtext` filter. Many static builds differ in encoders, filters, and protocol support.

So FFmix probes the actual binary (`ffmpeg -filters`, `-encoders`) and caches capabilities per path. Features degrade honestly: if your build can't burn subtitles, the burn-in option is disabled with an explanation — instead of failing at 0% with a cryptic `No such filter`.

## 4. Engine adaptation — the LGPL / VideoToolbox story

FFmix's canonical recipes are written for `libx264`/`libx265` (CRF, two-pass). But our embedded engine is **LGPL-only** — no GPL encoders. (This is deliberate: bundling x264/x265 carries the exact patent/licensing risk that contributed to [ffmpeg-kit's retirement in 2025](comparison.md#ffmpeg-kit).)

When the active engine lacks software encoders, commands are mechanically rewritten to Apple's hardware encoder:

| Canonical (full build) | Adapted (LGPL embedded engine) |
|---|---|
| `-c:v libx264` | `-c:v h264_videotoolbox -allow_sw 1` |
| `-c:v libx265` | `-c:v hevc_videotoolbox -allow_sw 1` |
| `-crf 18 / 23 / 28` | `-q:v 70 / 58 / 45` (VideoToolbox quality scale) |
| two-pass (`-pass 1/2`) | single-pass ABR (VT has no stats pass) |
| `-preset` / `-tune` | removed (x264-specific) |

Both forms are first-class: if you point FFmix at a full Homebrew build, you get real CRF and real two-pass. The command layer always shows the form that will actually run.

## 5. Execution — a real subprocess, treated with respect

- Commands run via `/bin/zsh -c` with two mechanical substitutions: `ffmpeg` → the resolved absolute path (GUI apps don't inherit your shell `$PATH`), and injection of `-nostdin -progress pipe:2 -nostats -y`.
- Progress is parsed from stderr's `out_time_ms=` against the duration AVFoundation read at import; `speed=` feeds the rate display.
- **Pause is `SIGSTOP`, resume is `SIGCONT`** — instant, free, and exactly what a queue wants. Cancel sends `SIGCONT` first (you can't terminate a stopped process cleanly), then terminates.
- Target-size compression runs a **real two-pass**: pass 1 (`-an -f null /dev/null`, progress 0–50%) → pass 2 (50–100%) → stats files cleaned up.
- On failure, the last 4KB of stderr is kept and translated into a human, three-part error (what happened / likely cause / what to do) — with the raw log one click away.

## 6. Output discipline

Outputs are written **next to the source** as `name-suffix.ext`, auto-numbered on conflict. FFmix never overwrites an original, ever. There is no "replace original" option to misclick.

## 7. The AI path — and why it can't betray you

Describing a task in one sentence ("compress this to 50MB and add my watermark") goes through three tiers:

1. **Local intent detection.** Simple single intents (compress / GIF / extract audio / convert / subtitles) are matched on-device with zero network traffic — marked with a "parsed locally" badge.
2. **Compound sentences** go to our API, which sends the model **only the sentence and an anonymous device id**. Never a file, never a filename, never metadata. Server-side, model output is sanitized against a whitelist (step count caps, known operations only) — malformed output falls back to a rule engine.
3. **Offline or failed?** A built-in rule-based fallback produces a pipeline anyway.

On *every* tier, the result is the same thing: a visible pipeline of steps, each showing its command, each editable or deletable. **Nothing executes until you confirm.** The AI proposes; you dispose.

## 8. Subtitles — local Whisper

Auto-subtitling runs [whisper.cpp](https://github.com/ggml-org/whisper.cpp) locally (Metal-accelerated, model downloaded once): ffmpeg extracts 16kHz mono WAV → whisper emits SRT → FFmix shows a proofread list where you can fix *text only* (timing stays bound to recognition) → burn in or export the SRT. Same privacy property: the audio never leaves the machine.

---

*Questions about any of this? [Open a discussion](../../../discussions) — design rationale is exactly the kind of thing we want to write more devlog entries about.*
