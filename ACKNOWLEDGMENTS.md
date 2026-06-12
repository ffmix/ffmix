# Acknowledgments

FFmix is a thin, careful layer over an extraordinary stack of open-source work. None of this product would exist without the projects below — "standing on the shoulders of giants" is the literal architecture diagram.

## The engine

| Project | What it does in FFmix | License |
|---|---|---|
| [FFmpeg](https://ffmpeg.org) | every media operation, full stop | LGPL-2.1+ (we use no GPL components) |
| [whisper.cpp](https://github.com/ggml-org/whisper.cpp) (ggml/Georgi Gerganov) | on-device speech-to-text for subtitles, Metal-accelerated | MIT |
| [libass](https://github.com/libass/libass) | subtitle rendering for burn-in | ISC |
| [FreeType](https://freetype.org) | font rasterization | FTL |
| [HarfBuzz](https://github.com/harfbuzz/harfbuzz) | text shaping | MIT (Old MIT) |
| [FriBidi](https://github.com/fribidi/fribidi) | bidirectional text (Arabic/Hebrew subtitles) | LGPL-2.1+ |
| [LAME](https://lame.sourceforge.io) | MP3 encoding | LGPL-2.0+ |
| [libvpx](https://github.com/webmproject/libvpx) | VP8/VP9 for WebM | BSD-3-Clause |
| [Opus](https://github.com/xiph/opus) | Opus audio | BSD-3-Clause |
| OpenAI [Whisper](https://github.com/openai/whisper) | the speech model weights whisper.cpp runs | MIT |

Exact versions, configure flags, and the full reproducible build live in [`engine/`](engine/).

## LGPL compliance, concretely

We take the obligations seriously rather than ceremonially:

- **Attribution** — kept in the app (About / Settings), on [ffmix.com](https://ffmix.com), and in [`engine/THIRD-PARTY.md`](engine/THIRD-PARTY.md).
- **Relinking** — LGPL requires that you can swap the LGPL libraries and relink. Our answer: the [public build script](engine/build-ffmpeg-lgpl-macos.sh) plus pinned source tarball URLs reproduce the embedded engine bit-for-bit equivalent; you can build your own and drop it into the app bundle (`Contents/MacOS/`) or just point FFmix at any ffmpeg binary in Settings.
- **Modifications** — we ship FFmpeg unmodified. The only source touch in the whole chain is a one-line compiler-warning pragma downgrade in HarfBuzz 2.9.1, disclosed in the build script itself.

## Projects that shaped the thinking

- [HandBrake](https://handbrake.fr), [LosslessCut](https://github.com/mifi/lossless-cut), [FFmpegFreeUI](https://github.com/Lake1059/FFmpegFreeUI), [ff·Works](https://www.ffworks.net/) — proof, in four different ways, that people want ffmpeg's power without ffmpeg's syntax. Our [comparison page](docs/comparison.md) tries to repay them with honest descriptions.
- [ffmpeg-kit](https://github.com/arthenica/ffmpeg-kit) and Taner Sener's candid [retirement post](https://tanersener.medium.com/saying-goodbye-to-ffmpegkit-33ae939767e1) — a masterclass in the legal and maintenance realities of distributing ffmpeg, which directly informed our LGPL + VideoToolbox engine design.
- The countless ffmpeg trac tickets, mailing-list threads, and Stack Overflow answers that document the behaviors in our [recipes page](docs/ffmpeg-recipes.md).

## Supporting upstream

Our intent is that once FFmix generates revenue, part of it flows back to [FFmpeg](https://ffmpeg.org/donations.html) — the single project we'd have no business without. If FFmix saves you time, consider donating to FFmpeg too.
