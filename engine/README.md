# FFmix engine — a reproducible LGPL static ffmpeg for macOS (Apple Silicon)

This directory contains the exact, reproducible build of the engine FFmix embeds:

- **ffmpeg 7.1.1, LGPL configuration** — static, single file, no Homebrew/dylib dependencies, App Store-distributable
- **whisper-cli 1.7.5** — whisper.cpp with Metal shaders *embedded in the binary* (single file, no resource bundle)

Run [`build-ffmpeg-lgpl-macos.sh`](build-ffmpeg-lgpl-macos.sh) on a Mac with Xcode CLT + Homebrew (for autotools/cmake only) and you get the same binaries we ship. This is both our [LGPL relinking obligation](../ACKNOWLEDGMENTS.md#lgpl-compliance-concretely) and, we think, useful on its own — a static libass-enabled ffmpeg for macOS is annoying to get right.

## What's in the build (and what deliberately isn't)

```
ffmpeg 7.1.1:  --enable-videotoolbox --enable-audiotoolbox        ← hardware H.264/HEVC/AAC
               --enable-libass --enable-libfreetype               ← subtitle burn-in + drawtext
               --enable-libharfbuzz --enable-libfribidi           ← real text shaping (CJK, RTL)
               --enable-libmp3lame --enable-libvpx --enable-libopus
               --disable-sdl2 --disable-libxcb --disable-xlib     ← no GUI/X11 baggage
               NO --enable-gpl → no x264, no x265                 ← see below
whisper-cli:   GGML_METAL=ON + GGML_METAL_EMBED_LIBRARY=ON        ← single-file Metal binary
target:        macOS 14.0+, arm64
```

**Why no x264/x265?** Two reasons, one legal and one practical:

1. `--enable-gpl` makes the whole binary GPL, and redistributing those encoders carries patent-license uncertainty — the risk that contributed to [ffmpeg-kit's retirement in January 2025](../docs/comparison.md#ffmpeg-kit). LGPL + VideoToolbox sidesteps both: H.264/HEVC encoding is an OS service Apple already licenses.
2. On Apple Silicon, VideoToolbox encodes are dramatically faster and cooler than software x264 for the "compress this screen recording" workloads a desktop tool mostly sees. (FFmix [mechanically adapts](../docs/how-it-works.md#4-engine-adaptation--the-lgpl--videotoolbox-story) CRF/two-pass recipes to VideoToolbox forms — and if you point it at a full ffmpeg build, you get real x264 back.)

## Build notes you'd otherwise learn the hard way

These are encoded in the script, with comments at the relevant lines:

- **`PKG_CONFIG_LIBDIR`, not `PKG_CONFIG_PATH`.** You must make pkg-config see *only* your static prefix, or ffmpeg's configure happily picks up Homebrew's dynamic SDL2/harfbuzz/X11 and your "static" binary grows dylib deps. (The script's final check runs `otool -L` and fails loudly on any non-system dependency.)
- **macOS system zlib has no `.pc` file**, and freetype's `Requires.private: zlib` makes pkg-config resolution fail under the strict isolation above → write a tiny stub `zlib.pc` pointing at `/usr/lib`.
- **HarfBuzz 2.9.1** is the last autotools release (newer needs meson); building 2021 code with clang 17 trips its self-imposed `-Werror=cast-function-type` — the script downgrades that one pragma and discloses it (our only source modification in the entire chain).
- **libass on macOS doesn't need fontconfig** — `--disable-fontconfig`, it uses CoreText for font selection. Saves a heavy dependency subtree.
- **Don't strip `LC_UUID`** to silence Xcode's dSYM warnings — modern dyld refuses to run binaries without a UUID. Instead generate matching dSYMs (`dsymutil`), which the script does and verifies.
- **`GGML_METAL_EMBED_LIBRARY=ON`** compiles whisper.cpp's Metal shaders into the executable — without it you must ship a `.metallib` next to the binary, which breaks inside an app bundle's `Contents/MacOS/`.

## Verify any FFmix engine yourself

```bash
ENGINE=~/Library/Application\ Support/FFmix/engine/ffmpeg
shasum -a 256 "$ENGINE"                     # compare with the manifest sha256
otool -L "$ENGINE" | grep -v -vE "/usr/lib/|/System/"   # only system deps
"$ENGINE" -version && "$ENGINE" -filters | grep subtitles
```

Or replace it entirely: build with this script, or `brew install ffmpeg`, and point FFmix at any binary in Settings → Tasks. The app treats your engine as first-class and probes its capabilities.

Component licenses and source links: [THIRD-PARTY.md](THIRD-PARTY.md).
