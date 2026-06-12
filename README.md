<div align="center">

# FFmix

**A native macOS GUI for FFmpeg — where the command you see is the command that runs.**

[Website](https://ffmix.com) · [How it works](docs/how-it-works.md) · [FFmpeg recipes & gotchas](docs/ffmpeg-recipes.md) · [Devlog](devlog/) · [中文 README](README.zh-CN.md)

</div>

---

FFmix is a macOS-native media tool: drop in video/audio/images → pick a task (or describe it in one sentence) → review the pipeline → run. Every job is a real, local `ffmpeg` process — and the exact command is always shown, editable, and copyable.

We are building it in public. This repository is FFmix's open home on GitHub:

| What's here | Why |
|---|---|
| [**FFmpeg recipes & gotchas**](docs/ffmpeg-recipes.md) | Every command FFmix generates, verified on real files — including the traps we hit (silent no-ops, build differences, version breakage). Useful even if you never run FFmix. |
| [**How FFmix works**](docs/how-it-works.md) | The architecture: a *translation layer* over ffmpeg, not a wrapper that hides it. |
| [**The native stack**](docs/native-stack.md) | SwiftUI, AVFoundation, VideoToolbox, `Process` + POSIX signals, whisper.cpp — how a Mac-assed Mac app drives ffmpeg. |
| [**LGPL ffmpeg build for macOS**](engine/) | The exact script that produces FFmix's embedded engine: static LGPL ffmpeg 7.1 (VideoToolbox + libass + whisper.cpp/Metal) for Apple Silicon. Reproducible, App Store-distributable. |
| [**Comparison with alternatives**](docs/comparison.md) | An honest look at HandBrake, FFmpegFreeUI, ffmpeg-kit, and friends — and when you should *not* use FFmix. |
| [**Devlog**](devlog/) | Build-in-public notes: decisions, dead ends, numbers. |
| [**Issues**](../../issues) | The public bug tracker and feature requests for the FFmix app. |

## The three contracts

Everything in FFmix is constrained by three product promises:

1. **Everything is processed locally.** Media files never leave your Mac. All processing is a local `ffmpeg` / `whisper.cpp` subprocess. The only thing that can touch the network is the optional AI feature — and it sends a single sentence of text, never a file.
2. **AI pipelines never run without your confirmation.** When you describe a task in natural language, the generated pipeline is shown step by step — editable, deletable — and nothing executes until you confirm.
3. **The command shown is the command run.** Every command string in the UI is the literal string handed to the engine. There is no hidden flag, no "simplified view". You can switch to manual mode and edit the raw command at any time.

If a feature would violate one of these, it doesn't ship.

## Why another ffmpeg GUI?

ffmpeg can do almost anything, and almost nobody can remember how. Existing answers each give something up:

- **Online converters** — you upload your files to someone else's server. Slow, size-capped, and a privacy non-starter.
- **Single-purpose apps** — one app to compress, another for GIFs, another for subtitles.
- **ffmpeg wrappers that hide the command** — fine until something fails, then you're debugging a black box.

FFmix's position: a **translation layer, not a black box**. The GUI builds real ffmpeg commands and shows them to you. Use it for years without reading a man page, or use it as the fastest way to *learn* ffmpeg — copy any command it generates and take it to your own terminal.

## Status

FFmix is in active development for **macOS 14+ (Apple Silicon)**, launching in 2026. Follow along:

- ⭐ Star this repo to follow the devlog
- 🌐 [ffmix.com](https://ffmix.com) — product site and launch updates
- 🐛 [Issues](../../issues) — bugs and feature requests welcome, before and after launch

## Is FFmix open source?

The FFmix app itself is a commercial product (one-time purchase, no subscription planned for core features). What *is* open, in this repo:

- the **engine build scripts** (LGPL compliance — you can reproduce our embedded ffmpeg bit-for-bit and even swap your own into the app bundle),
- all **documentation, recipes, and devlog** content,
- the **issue tracker**.

We think this is the honest version of "local-first": you can verify exactly what binary processes your files and exactly which commands run.

## Acknowledgments

FFmix exists because of FFmpeg, whisper.cpp, libass, and a long chain of open-source giants. See [ACKNOWLEDGMENTS.md](ACKNOWLEDGMENTS.md) — including how we comply with LGPL and how to relink the engine yourself.

## License

- Code in this repository (build scripts, snippets): [MIT](LICENSE)
- Documentation and devlog text: [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/)
- The FFmix application is proprietary. FFmpeg and other engine components remain under their own licenses — see [engine/THIRD-PARTY.md](engine/THIRD-PARTY.md).
