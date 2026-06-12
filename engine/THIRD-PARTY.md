# Embedded engine — third-party components and licenses

FFmix's embedded processing engine is statically linked from the following open-source components (no GPL components; H.264/H.265 encoding uses macOS system VideoToolbox). The full build script is [`build-ffmpeg-lgpl-macos.sh`](build-ffmpeg-lgpl-macos.sh) — reproducible verbatim.

| Component | Version | License | Source |
|---|---|---|---|
| FFmpeg | 7.1.1 | LGPL-2.1+ (no GPL components enabled) | https://ffmpeg.org/releases/ffmpeg-7.1.1.tar.xz |
| libass | 0.17.3 | ISC | https://github.com/libass/libass |
| HarfBuzz | 2.9.1 | MIT (Old MIT) | https://github.com/harfbuzz/harfbuzz |
| FreeType | 2.13.3 | FTL (BSD-style, dual) | https://freetype.org |
| FriBidi | 1.0.16 | LGPL-2.1+ | https://github.com/fribidi/fribidi |
| LAME | 3.100 | LGPL-2.0+ | https://lame.sourceforge.io |
| libvpx | 1.15.0 | BSD-3-Clause | https://github.com/webmproject/libvpx |
| Opus | 1.5.2 | BSD-3-Clause | https://github.com/xiph/opus |
| whisper.cpp | 1.7.5 | MIT | https://github.com/ggml-org/whisper.cpp |

## LGPL compliance (FFmpeg / FriBidi / LAME)

- Attribution and license links above are preserved in the app (About / Settings → Account) and on the website;
- LGPL requires users be able to relink against replacement LGPL libraries: we satisfy this with the **public build script + per-version source tarball links** (build an equivalent binary with the script and drop it into the app bundle's `Contents/MacOS/`, or point FFmix at any ffmpeg in Settings);
- Any source modification to FFmpeg must be published — there are none. The only source touch in the chain is a one-line compiler-warning pragma downgrade in HarfBuzz, disclosed inline in the build script.

## Build configuration summary

```
ffmpeg: --disable-gpl(default) --enable-videotoolbox --enable-audiotoolbox
        --enable-libass --enable-libfreetype --enable-libharfbuzz
        --enable-libfribidi --enable-libmp3lame --enable-libvpx --enable-libopus
        --disable-sdl2 --disable-libxcb --disable-xlib  (system-only dynamic deps)
whisper-cli: GGML_METAL=ON + GGML_METAL_EMBED_LIBRARY=ON (shaders embedded, single file)
target: macOS 14.0+ / arm64
```
