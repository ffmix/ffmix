# FFmix devlog — building in public

Notes from building a native macOS ffmpeg frontend: decisions, dead ends, numbers. New entries announced via repo releases/discussions — ⭐ watch the repo to follow.

| # | Date | Entry |
|---|---|---|
| 001 | 2026-06 | [The command you see is the command that runs](001-the-command-you-see.md) |

Planned entries (in no particular order — open an issue to vote):

- **Two-pass encoding with a progress bar users can trust** — mapping pass 1/pass 2 onto 0–50/50–100, and the `-passlogfile` concurrency trap
- **Pausing ffmpeg: the kernel already solved it** — SIGSTOP/SIGCONT, and why cancel needs SIGCONT first
- **What ffmpeg-kit's retirement taught us about shipping ffmpeg** — LGPL vs GPL builds, VideoToolbox, patents
- **Natural language → ffmpeg pipeline, without trusting the model** — local intent detection, output sanitization, and the confirmation contract
- **Rendering text watermarks without drawtext** — capability differences across ffmpeg builds, and moving work to the platform side
- **Whisper on-device: shipping a single-file Metal binary**
- **Why a 1040×700 SwiftUI window has zero third-party dependencies**
