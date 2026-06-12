# FFmpeg recipes & gotchas — verified on real files

These are the commands FFmix generates, written down with the *why* and the traps. Everything here was verified on real media files on macOS (ffmpeg 7.x/8.x), not copied from decade-old Stack Overflow answers — several of those answers are silently broken on modern ffmpeg, which is exactly why this page exists.

Conventions: `in.mp4`/`out.mp4` placeholders; commands are single-line; software-encoder forms shown first, with [VideoToolbox equivalents](#videotoolbox-equivalents) at the end.

---

## Compress to a target file size (real two-pass)

Bitrate math first — this is the part most GUIs get wrong:

```
video_kbps = target_MB × 8192 / duration_seconds − 128 (audio budget)
```

Clamp to a floor (FFmix uses 320 kbps — below that, admit the target is unrealistic instead of producing soup). Then:

```bash
# pass 1 — analysis only: no audio, null output
ffmpeg -y -i in.mp4 -c:v libx264 -b:v 1200k -maxrate 1440k -bufsize 2400k \
  -pass 1 -passlogfile /tmp/ff2pass -an -f null /dev/null
# pass 2 — actual encode
ffmpeg -y -i in.mp4 -c:v libx264 -b:v 1200k -maxrate 1440k -bufsize 2400k \
  -pass 2 -passlogfile /tmp/ff2pass -c:a aac -b:a 128k out.mp4
```

**Gotchas:**
- `-maxrate 1.2×` + `-bufsize 2×` keeps spikes from blowing the target on hard scenes.
- Use a private `-passlogfile` and clean it up — concurrent jobs sharing the default `ffmpeg2pass-0.log` corrupt each other.
- Sanity-check duration with a real probe before doing the math; container metadata lies on some screen recordings.

## Compress by quality (CRF)

```bash
ffmpeg -i in.mp4 -c:v libx264 -crf 23 -preset medium -c:a copy out.mp4
```

CRF 18 ≈ visually lossless, 23 = sane default, 28 = small. `-preset` trades encode time for compression efficiency, not quality.

## Video → GIF that doesn't look like 1998

```bash
ffmpeg -i in.mp4 -vf "fps=12,scale=480:-1:flags=lanczos,split[a][b];[a]palettegen[p];[b][p]paletteuse" out.gif
```

**Gotcha:** a naive `-vf scale` GIF uses a generic 256-color palette and dithers horribly. `palettegen`/`paletteuse` computes a per-clip palette in one pass via `split`. `fps=12` halves size with little perceptual loss for UI/screen content.

## Concatenate

Three different problems, three different commands:

```bash
# 1. Same codec/resolution → stream copy, finishes in seconds
ffmpeg -f concat -safe 0 -i list.txt -c copy out.mp4
# list.txt:  file '/absolute/path/a.mp4'  (one per line, ABSOLUTE paths)

# 2. Mixed resolutions → normalize first (FFmix unifies to 1080p), then concat filter

# 3. Crossfade between two clips
ffmpeg -i a.mp4 -i b.mp4 -filter_complex \
  "xfade=transition=fade:duration=0.5:offset=DUR_A-0.5;acrossfade=d=0.5" out.mp4
```

**Gotchas:**
- The concat *demuxer* (case 1) needs `-safe 0` for absolute paths — and you want absolute paths, because relative ones resolve against the list file, not your cwd.
- `xfade`'s `offset` is measured from the start of the **first** input: `offset = duration_A − fade_duration`. Get it wrong and the second clip is silently truncated or the fade never happens.
- Don't crossfade with `-c copy`. Any filter means re-encode.

## Watermarks (image *and* text) without `drawtext`

```bash
# image watermark, bottom-right with 24px margin, 60% opacity
ffmpeg -i in.mp4 -i logo.png -filter_complex \
  "[1]colorchannelmixer=aa=0.6[wm];[0][wm]overlay=W-w-24:H-h-24" out.mp4
```

**The trap:** every tutorial says use `drawtext` for text watermarks. `drawtext` requires a freetype-enabled build — **Homebrew's default ffmpeg 8.x has no freetype/libass**, so the filter simply doesn't exist there. FFmix sidesteps it entirely: render the text to a transparent PNG on the app side (Core Graphics — any system font, proper CJK), then use the image path above. If you're scripting, one `magick -background none label:"© you" wm.png` gets you the same robustness.

## Speed up / slow down, pitch preserved

```bash
# 2× with natural-sounding audio
ffmpeg -i in.mp4 -vf "setpts=PTS/2" -af "atempo=2" out.mp4
# 4× — atempo only accepts 0.5–2.0 per instance, so CHAIN it:
ffmpeg -i in.mp4 -vf "setpts=PTS/4" -af "atempo=2,atempo=2" out.mp4
# chipmunk mode (pitch shifts with speed): asetrate=48000*2,aresample=48000
```

**Gotcha:** `atempo` outside [0.5, 2.0] errors out. n× speed = chain of log₂(n) `atempo=2` instances (e.g. 3× = `atempo=2,atempo=1.5`).

## Rotation: the ffmpeg 7+ silent no-op

This one cost us a day. Since ffmpeg 7, the old metadata rotation incantation **does nothing — successfully**:

```bash
# ❌ exits 0, writes a file, rotates NOTHING (ffmpeg 7+):
ffmpeg -i in.mp4 -metadata:s:v rotate=90 -c copy out.mp4

# ✅ lossless 90°/180° rotation, no re-encode — note it's an INPUT option:
ffmpeg -display_rotation 90 -i in.mp4 -c copy out.mp4

# mirroring genuinely needs a re-encode:
ffmpeg -i in.mp4 -vf hflip out.mp4   # or vflip
```

`-display_rotation` rewrites the display matrix on the way in — instant and lossless. It must appear **before** `-i`.

## Burn subtitles (and survive ffmpeg 8)

```bash
ffmpeg -i in.mp4 -vf "subtitles=filename='subs.srt':force_style='FontSize=24'" out.mp4
```

**Two traps:**
1. **ffmpeg 8's new filtergraph parser requires the named option.** The classic `subtitles='subs.srt'` positional form breaks; `subtitles=filename='…'` works on both 7 and 8.
2. The `subtitles` filter needs **libass**, which (again) Homebrew's default build lacks. Probe before you promise: `ffmpeg -filters | grep subtitles`. FFmix disables burn-in with an explanation when the active engine can't do it.

## Extract / strip audio

```bash
ffmpeg -i in.mp4 -vn -c:a libmp3lame -b:a 320k out.mp3   # MP3
ffmpeg -i in.mp4 -vn -c:a pcm_s16le out.wav              # WAV (e.g. for Whisper)
ffmpeg -i in.mp4 -vn -c:a flac out.flac                  # lossless
ffmpeg -i in.mp4 -an -c:v copy out.mp4                   # remove audio — no re-encode
```

## Whisper preprocessing

whisper.cpp wants 16 kHz mono:

```bash
ffmpeg -i in.mp4 -vn -ac 1 -ar 16000 -c:a pcm_s16le audio.wav
```

## Driving ffmpeg from a program (what a GUI must do)

```bash
ffmpeg -nostdin -progress pipe:2 -nostats -y -i in.mp4 ... out.mp4
```

- `-nostdin` — or ffmpeg will block forever on an overwrite prompt you can't see.
- `-progress pipe:2 -nostats` — machine-readable `key=value` progress on stderr; compute percent as `out_time_ms / total_duration`. (`out_time_ms` is **microseconds** despite the name.)
- **Pause/resume:** there is no ffmpeg API, but `SIGSTOP`/`SIGCONT` is flawless — zero CPU while stopped, instant resume. Send `SIGCONT` before terminating a stopped process.
- GUI apps on macOS don't inherit shell `$PATH` — resolve and substitute the absolute binary path.
- Keep the stderr tail (last ~4 KB) on failure; that's where the actionable error lives.

## VideoToolbox equivalents

On Apple Silicon, hardware encoding via VideoToolbox is fast, cool, and — relevant if you distribute an app — **free of the GPL/patent baggage of bundling x264/x265**:

```bash
ffmpeg -i in.mp4 -c:v h264_videotoolbox -allow_sw 1 -q:v 58 -c:a copy out.mp4
ffmpeg -i in.mp4 -c:v hevc_videotoolbox -allow_sw 1 -q:v 58 -tag:v hvc1 -c:a copy out.hevc.mp4
```

Mapping FFmix uses when adapting CRF recipes:

| x264 CRF | VideoToolbox `-q:v` (1–100, higher = better) |
|---|---|
| 18 (high) | 70 |
| 23 (medium) | 58 |
| 28 (low) | 45 |

No two-pass (no stats pass in the hardware), so target-size jobs become single-pass ABR: `-b:v target -maxrate 1.2× -bufsize 2×`. `-allow_sw 1` lets VideoToolbox fall back to its software path on machines without the encode block.

## Output hygiene

Write `name-suffix.ext` next to the source and auto-number on conflict. **Never overwrite the input** — `-y` plus a careless output path is how people lose originals. (FFmix has no "overwrite original" option by design.)

---

**Found an error, or have a hard-won recipe of your own?** [Issues and PRs welcome](../../../issues) — recipes must state the ffmpeg version they were verified on.
