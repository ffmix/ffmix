# The native stack: SwiftUI + AVFoundation + VideoToolbox + ffmpeg

FFmix is a SwiftUI app for macOS 14+ (Apple Silicon) with **zero third-party Swift dependencies**. No Electron, no Sparkle, no Alamofire, no SwiftUI component kits. This page explains what the native platform gives a media tool, and the specific patterns we use.

## Why native (and why no dependencies)

A media utility lives or dies on feel: instant launch, native drag-and-drop with real file promises, a menu-bar presence, low idle footprint, and OS-level integration (login items, Services, sandboxing for App Store). Electron taxes all of these — the category leader [LosslessCut](https://github.com/mifi/lossless-cut) is excellent *despite* Electron, not because of it.

Zero dependencies is a deliberate constraint, not machismo: every behavior in the app is code we can read, and the attack/maintenance surface of a tool that handles personal media stays minimal. The platform turns out to provide everything a media GUI needs:

| Need | Platform API |
|---|---|
| Probe duration / resolution / codec | `AVAsset` (AVFoundation) |
| First-frame thumbnails | `AVAssetImageGenerator` |
| H.264/H.265 encoding without GPL encoders | **VideoToolbox** via ffmpeg's `h264_videotoolbox` / `hevc_videotoolbox` |
| Text watermark rendering | Core Graphics → transparent PNG (see below) |
| Run & control ffmpeg | `Process` + POSIX signals |
| Watch folders | `DispatchSource.makeFileSystemObjectSource` |
| Menu-bar app | SwiftUI `MenuBarExtra(.window)` |
| Launch at login | `SMAppService` |
| Speech-to-text | whisper.cpp with Metal (`GGML_METAL_EMBED_LIBRARY`) |

## State: one observable store, UI as a pure function

The whole app is three layers: **Views → a single `@MainActor ObservableObject` store → engines**. Routing, files, drawers, the job queue, overlays, toasts — all flow through one `AppState`. Every view is a pure function of that state, which is what makes the app's behavior predictable enough to keep the "shown == run" contract.

Two SwiftUI lessons that cost us real debugging time:

- **Never write to `@Published`/`@AppStorage` inside the store's synchronous `init`** — it fires during the `@StateObject` render pass and you get *"Publishing changes from within view updates"*. Persisted collections load as initial wrapped values; other startup writes defer via `Task { @MainActor in … }`.
- **An `@AppStorage` default of `true` doesn't exist in `UserDefaults` until first written.** Any raw `UserDefaults` read of the same key (e.g. from an `NSApplicationDelegate` method that runs outside SwiftUI) needs its own explicit fallback.

## AVFoundation at import time

ffmpeg could probe files (`ffprobe`), but AVFoundation does it without spawning a process: synchronous size/type check on drop, then async `AVAsset` loading for duration, dimensions, codec name, and a first-frame thumbnail. Files that fail to load are flagged broken — red border, skipped at execution, never blocking a batch.

A nice consequence of native: the **result card supports `onDrag` with the real output file URL** — you drag a finished file straight into Finder, Slack, or WeChat.

## VideoToolbox: the encoder that ships

Apple Silicon has dedicated H.264/HEVC encode blocks, exposed via VideoToolbox. ffmpeg wraps them as `h264_videotoolbox` / `hevc_videotoolbox`. For FFmix this solves a legal problem and a performance problem at once:

- **Legal:** distributing `libx264`/`libx265` makes the binary GPL and raises patent questions ([this contributed to ffmpeg-kit's retirement](comparison.md#ffmpeg-kit)). VideoToolbox encoding is an OS service — the LGPL ffmpeg build just calls into macOS.
- **Performance:** hardware encode is fast and cool. The trade-off is rate control: no CRF, no two-pass stats. FFmix maps CRF quality tiers to `-q:v` (70/58/45) and converts two-pass to single-pass ABR, with `-allow_sw 1` so old machines fall back to software inside VideoToolbox itself.

Quality-critical users can point FFmix at a full ffmpeg build and get real x264 CRF — the adaptation only kicks in when the active engine lacks the encoder.

## Driving ffmpeg with `Process` + signals

The engine layer is ~one file. The interesting parts:

- **GUI apps don't inherit your shell `$PATH`** — the resolved absolute ffmpeg path is substituted into the command before launch.
- `-nostdin` (ffmpeg must never block waiting for `y/N` in a GUI), `-progress pipe:2 -nostats` for machine-readable progress on stderr.
- Progress = `out_time_ms` ÷ duration (from AVFoundation). `speed=` gives the ×-rate display.
- **Pause/resume = `SIGSTOP`/`SIGCONT`.** ffmpeg has no pause API, but the kernel does, and it's perfect: zero CPU while paused, instant resume, encoder state intact. One subtlety: before cancelling a paused job, send `SIGCONT` first — a stopped process can't handle the termination cleanly.

## Text watermarks without `drawtext`

The obvious approach — ffmpeg's `drawtext` filter — fails on real-world builds: it requires freetype, which many distributions (including Homebrew's default 8.x build) don't compile in. FFmix instead renders the text **in-app with Core Graphics** to a transparent PNG, then overlays it like an image watermark (`overlay=X:Y` + `colorchannelmixer=aa=α`). Native text rendering also means real system fonts, proper CJK shaping, and WYSIWYG preview for free.

This is the pattern worth generalizing: **when ffmpeg's capability varies across builds, move the work to the platform side and feed ffmpeg something universal.**

## Watch folders without polling

Pro users bind a preset to a folder: anything dropped in gets processed automatically. Implementation is a `DispatchSource` file-system object source on the directory (`.write` events) — kernel-level notification, no polling timers. Combined with `SMAppService` login launch, a Mac mini in a corner becomes a drop-box transcoder.

## whisper.cpp with embedded Metal shaders

Subtitle recognition uses a `whisper-cli` built with `GGML_METAL=ON` and `GGML_METAL_EMBED_LIBRARY=ON` — the Metal shader library is embedded in the binary, so it ships as a **single file** with no resource-bundle path issues inside an app wrapper. Models download once into Application Support; recognition runs entirely on-device.

---

*The exact build flags for everything above are in [`engine/build-ffmpeg-lgpl-macos.sh`](../engine/build-ffmpeg-lgpl-macos.sh) — reproducible, and discussed in [the engine README](../engine/README.md).*
