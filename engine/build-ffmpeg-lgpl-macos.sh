#!/bin/zsh
# FFmix embedded engine build — static LGPL ffmpeg (VideoToolbox hardware encode +
# libass subtitles + freetype/drawtext + LAME MP3) and whisper-cli (Metal, shaders
# embedded). Produces single-file binaries in ./dist with no third-party dylib deps.
#
# License chain: LGPL/BSD/ISC/MIT/FTL throughout — NO GPL components, so the result
# is App Store-distributable. LGPL obligations (attribution + source availability +
# relinking) are satisfied by this script being public; see THIRD-PARTY.md.
#
# Requirements: Xcode Command Line Tools; Homebrew only for build tools
# (autoconf/automake/cmake/pkg-config/perl), never for libraries.
#
# Usage: ./build-ffmpeg-lgpl-macos.sh [build-root]   (default /tmp/ffmix-engine-build)
set -euo pipefail

ROOT="${1:-/tmp/ffmix-engine-build}"
DIST="$(cd "$(dirname "$0")" && pwd)/dist"
PREFIX="$ROOT/prefix"
JOBS=$(sysctl -n hw.ncpu)
MACOS_MIN=14.0
export PATH="/opt/homebrew/bin:$PATH"
# PKG_CONFIG_LIBDIR (not PKG_CONFIG_PATH) = pkg-config sees ONLY our prefix —
# otherwise ffmpeg's configure picks up Homebrew's dynamic libs (SDL2/harfbuzz/X11…)
# and silently breaks the static link.
export PKG_CONFIG_LIBDIR="$PREFIX/lib/pkgconfig"
export CFLAGS="-O2 -mmacosx-version-min=$MACOS_MIN -I$PREFIX/include"
export CXXFLAGS="$CFLAGS"
# Note: do NOT use -no_uuid to strip LC_UUID (it silences Xcode dSYM warnings but
# modern dyld refuses to run executables without a UUID). Instead we keep the UUID
# and generate matching dSYMs in the collect step.
export LDFLAGS="-mmacosx-version-min=$MACOS_MIN -L$PREFIX/lib"

mkdir -p "$ROOT/src" "$PREFIX/lib/pkgconfig" "$DIST"
cd "$ROOT/src"

# Under strict isolation the macOS system zlib has no .pc file (freetype2.pc's
# "Requires.private: zlib" would fail to resolve) → write a stub pointing at the
# system libz.
cat > "$PREFIX/lib/pkgconfig/zlib.pc" <<'PC'
prefix=/usr
libdir=${prefix}/lib
includedir=${prefix}/include

Name: zlib
Description: macOS system zlib
Version: 1.2.12
Libs: -lz
Cflags:
PC

fetch() { # url file
  [ -f "$2" ] || curl -fL --retry 3 --max-time 600 -o "$2" "$1"
}

step() { echo "\n===== [$(date +%H:%M:%S)] $1 ====="; }

# ---------- freetype (font rasterization; needed by libass/drawtext) ----------
step "freetype 2.13.3"
if [ ! -f "$PREFIX/lib/libfreetype.a" ]; then
fetch https://download.savannah.gnu.org/releases/freetype/freetype-2.13.3.tar.xz freetype.tar.xz
rm -rf freetype-2.13.3 && tar xf freetype.tar.xz && cd freetype-2.13.3
./configure --prefix="$PREFIX" --enable-static --disable-shared \
  --with-zlib=yes --without-png --without-brotli --without-harfbuzz --without-bzip2 > build.log 2>&1
make -j"$JOBS" >> build.log 2>&1 && make install >> build.log 2>&1
cd ..
fi

# ---------- fribidi (bidirectional text; needed by libass) ----------
step "fribidi 1.0.16"
if [ ! -f "$PREFIX/lib/libfribidi.a" ]; then
fetch https://github.com/fribidi/fribidi/releases/download/v1.0.16/fribidi-1.0.16.tar.xz fribidi.tar.xz
rm -rf fribidi-1.0.16 && tar xf fribidi.tar.xz && cd fribidi-1.0.16
./configure --prefix="$PREFIX" --enable-static --disable-shared > build.log 2>&1
make -j"$JOBS" >> build.log 2>&1 && make install >> build.log 2>&1
cd ..
fi

# ---------- harfbuzz (text shaping; 2.9.1 = last autotools release) ----------
step "harfbuzz 2.9.1"
if [ ! -f "$PREFIX/lib/libharfbuzz.a" ]; then
fetch https://github.com/harfbuzz/harfbuzz/releases/download/2.9.1/harfbuzz-2.9.1.tar.xz harfbuzz.tar.xz
rm -rf harfbuzz-2.9.1 && tar xf harfbuzz.tar.xz
# 2021 code × clang 17: hb.hh promotes the -Wcast-function-type family to errors,
# which now trips a newer strict variant (FT_Generic_Finalizer cast). Downgrade
# that one pragma to "ignored" — this is the ONLY source modification in the chain.
perl -pi -e 's/#pragma GCC diagnostic error   "-Wcast-function-type"/#pragma GCC diagnostic ignored "-Wcast-function-type"/' \
  harfbuzz-2.9.1/src/hb.hh
cd harfbuzz-2.9.1
./configure --prefix="$PREFIX" --enable-static --disable-shared \
  --with-freetype=yes --with-glib=no --with-cairo=no --with-icu=no --with-coretext=yes > build.log 2>&1
make -j"$JOBS" >> build.log 2>&1 && make install >> build.log 2>&1
cd ..
fi

# ---------- libass (subtitle rendering; uses CoreText on macOS, no fontconfig) ----------
step "libass 0.17.3"
if [ ! -f "$PREFIX/lib/libass.a" ]; then
fetch https://github.com/libass/libass/releases/download/0.17.3/libass-0.17.3.tar.xz libass.tar.xz
rm -rf libass-0.17.3 && tar xf libass.tar.xz && cd libass-0.17.3
./configure --prefix="$PREFIX" --enable-static --disable-shared --disable-fontconfig > build.log 2>&1
make -j"$JOBS" >> build.log 2>&1 && make install >> build.log 2>&1
cd ..
fi

# ---------- lame (MP3 encoding, LGPL) ----------
step "lame 3.100"
if [ ! -f "$PREFIX/lib/libmp3lame.a" ]; then
fetch "https://downloads.sourceforge.net/project/lame/lame/3.100/lame-3.100.tar.gz" lame.tar.gz
rm -rf lame-3.100 && tar xf lame.tar.gz && cd lame-3.100
./configure --prefix="$PREFIX" --enable-static --disable-shared --disable-frontend > build.log 2>&1
make -j"$JOBS" >> build.log 2>&1 && make install >> build.log 2>&1
cd ..
fi

# ---------- libvpx (VP8/VP9 for WebM; BSD) ----------
step "libvpx 1.15.0"
if [ ! -f "$PREFIX/lib/libvpx.a" ]; then
fetch https://github.com/webmproject/libvpx/archive/refs/tags/v1.15.0.tar.gz libvpx.tar.gz
rm -rf libvpx-1.15.0 && tar xf libvpx.tar.gz && cd libvpx-1.15.0
./configure --prefix="$PREFIX" --disable-shared --enable-static --enable-pic \
  --enable-vp8 --enable-vp9 --disable-examples --disable-tools --disable-docs \
  --disable-unit-tests > build.log 2>&1
make -j"$JOBS" >> build.log 2>&1 && make install >> build.log 2>&1
cd ..
fi

# ---------- opus (WebM audio; BSD) ----------
step "opus 1.5.2"
if [ ! -f "$PREFIX/lib/libopus.a" ]; then
fetch https://github.com/xiph/opus/releases/download/v1.5.2/opus-1.5.2.tar.gz opus.tar.gz
rm -rf opus-1.5.2 && tar xf opus.tar.gz && cd opus-1.5.2
./configure --prefix="$PREFIX" --enable-static --disable-shared \
  --disable-doc --disable-extra-programs > build.log 2>&1
make -j"$JOBS" >> build.log 2>&1 && make install >> build.log 2>&1
cd ..
fi

# ---------- ffmpeg (LGPL: no --enable-gpl, hence no x264/x265) ----------
step "ffmpeg 7.1.1 (LGPL static)"
fetch https://ffmpeg.org/releases/ffmpeg-7.1.1.tar.xz ffmpeg.tar.xz
rm -rf ffmpeg-7.1.1 && tar xf ffmpeg.tar.xz && cd ffmpeg-7.1.1
./configure --prefix="$PREFIX" \
  --pkg-config-flags="--static" \
  --extra-cflags="$CFLAGS" --extra-ldflags="$LDFLAGS" \
  --disable-shared --enable-static \
  --disable-debug --disable-doc --disable-ffplay --disable-ffprobe \
  --disable-sdl2 --disable-libxcb --disable-xlib --disable-securetransport \
  --enable-videotoolbox --enable-audiotoolbox \
  --enable-libass --enable-libfreetype --enable-libharfbuzz --enable-libfribidi \
  --enable-libmp3lame --enable-libvpx --enable-libopus > configure.log 2>&1
make -j"$JOBS" > build.log 2>&1 && make install >> build.log 2>&1
cd ..

# ---------- whisper.cpp (Metal shaders embedded → single-file binary) ----------
step "whisper.cpp v1.7.5"
fetch https://github.com/ggml-org/whisper.cpp/archive/refs/tags/v1.7.5.tar.gz whisper.tar.gz
if [ ! -f whisper.cpp-1.7.5/build/bin/whisper-cli ]; then
rm -rf whisper.cpp-1.7.5 && tar xf whisper.tar.gz
fi
cd whisper.cpp-1.7.5
cmake -B build -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=OFF \
  -DGGML_METAL=ON -DGGML_METAL_EMBED_LIBRARY=ON \
  -DWHISPER_BUILD_TESTS=OFF -DWHISPER_BUILD_EXAMPLES=ON \
  -DCMAKE_OSX_DEPLOYMENT_TARGET=$MACOS_MIN > cmake.log 2>&1
cmake --build build -j"$JOBS" --target whisper-cli > build.log 2>&1
cd ..

# ---------- collect → dist ----------
step "collect → $DIST"
cp "$PREFIX/bin/ffmpeg" "$DIST/ffmpeg"
cp "$ROOT/src/whisper.cpp-1.7.5/build/bin/whisper-cli" "$DIST/whisper-cli"
strip -x "$DIST/ffmpeg" "$DIST/whisper-cli" || true
chmod 755 "$DIST/ffmpeg" "$DIST/whisper-cli"

# dSYMs with UUIDs matching the binaries (even without debug symbols) — when the
# binaries are embedded in an app, Xcode's archive step finds them by UUID and the
# missing-dSYM upload warning goes away.
for b in ffmpeg whisper-cli; do
  rm -rf "$DIST/$b.dSYM"
  dsymutil "$DIST/$b" -o "$DIST/$b.dSYM" 2>/dev/null || true
done

echo "\n===== verify ====="
"$DIST/ffmpeg" -version | head -2
echo "--- all third-party libs must be static (only /usr/lib and system frameworks allowed) ---"
otool -L "$DIST/ffmpeg" | tail -n +2 | grep -v -E "/usr/lib/|/System/" && echo "!! non-system dynamic dependency found" || echo "OK: system deps only"
echo "--- dSYM UUIDs must match the binaries ---"
for b in ffmpeg whisper-cli; do
  bin=$(otool -l "$DIST/$b" | grep uuid | awk '{print $2}')
  dsym=$(dwarfdump --uuid "$DIST/$b.dSYM" 2>/dev/null | awk '{print $2}' | head -1)
  [ -n "$bin" ] && [ "$bin" = "$dsym" ] && echo "OK: $b UUID matches $bin" || echo "!! $b UUID mismatch bin=$bin dSYM=$dsym"
done
echo "--- key capabilities ---"
"$DIST/ffmpeg" -hide_banner -filters 2>/dev/null | grep -cE " (subtitles|drawtext) " | xargs echo "subtitles+drawtext filters:"
"$DIST/ffmpeg" -hide_banner -encoders 2>/dev/null | grep -E "videotoolbox|libmp3lame|libvpx|libopus" | head -8
"$DIST/whisper-cli" --help 2>&1 | head -2
ls -lh "$DIST/ffmpeg" "$DIST/whisper-cli"
echo "DONE"
