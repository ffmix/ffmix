# FFmix and the alternatives — an honest comparison

The ffmpeg-frontend space has excellent projects in it, several of which we use and admire. This page is for picking the right tool, including the cases where the right tool **isn't FFmix**. Facts below were checked against the projects' repos/announcements in June 2026; corrections welcome via issue.

## TL;DR table

| | FFmix | [FFmpegFreeUI (3FUI)](https://github.com/Lake1059/FFmpegFreeUI) | [ffmpeg-kit](https://github.com/arthenica/ffmpeg-kit) | [HandBrake](https://github.com/HandBrake/HandBrake) | [LosslessCut](https://github.com/mifi/lossless-cut) |
|---|---|---|---|---|---|
| What it is | macOS GUI, task-first | Windows GUI, parameter-first | developer library (retired) | cross-platform transcoder | lossless cut/remux tool |
| Platform | macOS 14+ (Apple Silicon) | Windows 10+ | Android/iOS/Flutter/RN | macOS/Win/Linux | macOS/Win/Linux (Electron) |
| Audience | anyone with a media chore | encoding enthusiasts, "画质党" | app developers | rip/transcode users | editors trimming footage |
| Command transparency | **command shown == command run, editable** | parameters exposed in full | N/A (API) | hidden (own engine) | partially visible |
| Natural-language → pipeline | ✅ (confirmed before run, text-only to cloud) | ❌ | ❌ | ❌ | ❌ |
| ffmpeg binary | embedded LGPL build *or* your own | bring your own | bundled per variant | own libav-based engine | bundled |
| Hardware encode (Mac) | VideoToolbox | NVENC/QSV/AMF (Windows) | VideoToolbox (non-LTS) | VideoToolbox | remux ≠ encode |
| License / price | proprietary app, one-time purchase; open docs & engine scripts | MIT, free | LGPL-3.0/GPL-3.0, archived | GPL-2.0, free | GPL-2.0, free |
| Status (June 2026) | in development, launching 2026 | active (v5.2 stable, v6 beta) | **retired 2025-01-06** | active | active |

## FFmpegFreeUI (3FUI)

A genuinely impressive Windows project: ~7k stars, actively developed, VB.NET/WinForms with a custom UI library, 40+ video encoders surfaced (NVENC/QSV/AMF hardware paths, x264/x265/AV1/VVC software), unlimited batch queue, a .NET plugin system, even libplacebo upscaling. MIT licensed.

The philosophical difference is the interesting part. 3FUI's own README says it targets people willing to learn — enthusiasts, quality perfectionists, encoding professionals — and deliberately ships *without* hand-holding presets. It is **parameter-first**: the GUI is a control surface for ffmpeg's full switchboard, and it expects you to know what CRF and reference frames are. It also expects you to supply your own ffmpeg build.

FFmix is **task-first**: you say what you want ("make this fit in a 25MB WeChat upload"), and the parameters are derived — but, unlike most task-first tools, the resulting command stays visible and editable, so the ceiling stays high. And FFmix is macOS-native where 3FUI is Windows-only; they don't actually compete for a single user's desktop.

**Choose 3FUI if:** you're on Windows and you enjoy encoding as a craft.

## ffmpeg-kit

For years, `ffmpeg-kit` (successor to MobileFFmpeg) was *the* way to run ffmpeg inside Android/iOS/Flutter/React Native apps — 5.8k stars, eight prebuilt variants from `min` to `full-gpl`.

On **January 6, 2025, it was officially retired** and the repo archived. The maintainer's farewell post cites two reasons worth reading carefully if you ship media software:

1. **Maintenance burden** — tracking ffmpeg releases across six platforms outgrew one person's available time.
2. **Legal uncertainty** — after the MPEG LA / Via-LA transition, patent-license status for the distributed binaries couldn't be confirmed (Via-LA never replied), and IP counsel advised retiring the project and pulling old binaries from Maven Central, CocoaPods, and npm.

Two takeaways shaped FFmix:

- **The patent/GPL risk of redistributing x264/x265 is not theoretical.** It helped kill the most popular ffmpeg distribution project in the mobile ecosystem. FFmix's embedded engine is **LGPL-only** — H.264/HEVC encoding goes through Apple's VideoToolbox (an OS service, licensed by Apple), and our [build script](../engine/) is public and reproducible.
- ffmpeg-kit was a *library for developers*; FFmix is an *app for end users*. Different layer — but anyone evaluating "how do I ship ffmpeg in a product" should study why ffmpeg-kit ended.

**Choose a community ffmpeg-kit fork if:** you're a developer embedding ffmpeg in a mobile app — and read the retirement post first.

## HandBrake

The 23k-star institution. To be precise, HandBrake is not an ffmpeg GUI — it's a transcoder with its own engine and preset system built on libav* components. It is superb at what it does: ripping and batch-transcoding to a target device/preset, with mature filters (deinterlace, denoise) and a huge community.

What it isn't: a general media multitool, or transparent. There's no concept of "show me the command", no GIF pipeline, no watermarking, no audio extraction workflows, no subtitles-from-speech. Preset-first and parameter-deep at once, its UI density is famously intimidating to casual users.

**Choose HandBrake if:** your job is *transcoding video files*, full stop — especially batch device-targeted conversion. It's free, GPL, and excellent.

## LosslessCut

41k stars, category-adjacent rather than competing: LosslessCut is about **cutting and remuxing without re-encoding** — trimming camera footage instantly. FFmix's no-re-encode operations (stream-copy concat, `-display_rotation`, `-an -c:v copy`) overlap slightly, but if your day is "cut 40 GoPro clips", LosslessCut is the purpose-built answer. It's also the strongest evidence that ffmpeg frontends with a clear opinion can find a massive audience.

## ff·Works, Shutter Encoder, and the rest of the Mac field

- **[ff·Works](https://www.ffworks.net/)** (€22, proprietary) — the closest existing thing to "ffmpeg control surface for Mac": full-parameter, professional, command-visible. Parameter-first like 3FUI; no natural-language layer, no task pipelines.
- **[Shutter Encoder](https://github.com/paulpacifico/shutter-encoder)** (GPL, Java) — free, aimed at video professionals/DITs; function-list UI, very capable, distinctly un-Mac-like.
- **Online converters** (CloudConvert et al.) — the anti-pattern FFmix exists to replace: uploading private footage to a server, with size caps and queue times, for something your own hardware does faster.

## Where FFmix actually stands

The honest gap in the market, as we see it: on macOS you can have a **preset black box** (HandBrake), a **full-parameter pro console** (ff·Works; 3FUI on Windows), or a **single-purpose tool** (LosslessCut, Gifski). Nobody offers *task-level intent* (including natural language) that compiles to a *reviewable, editable, local command pipeline*. That middle path — approachable like a black box, transparent like a console — is the entire bet behind FFmix.

And the cases where you should not use FFmix, stated plainly:

- You need Windows or Linux → 3FUI, HandBrake, Shutter Encoder.
- You batch-rip discs or transcode libraries against device presets → HandBrake.
- You mostly trim/split footage losslessly → LosslessCut.
- You want open-source end to end → HandBrake, LosslessCut, 3FUI are all there. FFmix opens its docs, recipes, and engine build — the app itself is a paid product; that's what funds the work.
