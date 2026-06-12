# Contributing

This repo is FFmix's open home — docs, recipes, engine build, devlog, and the app's public tracker. Ways to contribute:

## Recipes (most wanted)

Found an error in [ffmpeg-recipes.md](docs/ffmpeg-recipes.md), or have a hard-won command + gotcha of your own? PRs welcome. House rules:

- State the **ffmpeg version(s) you verified on** and the platform.
- Include the *why* and the trap, not just the command — the gotcha is the value.
- One recipe per PR keeps review fast.

## Bug reports & feature requests for the app

Use [issues](../../issues). For bugs, the in-app "View log" output (raw ffmpeg stderr) is the single most useful thing you can attach — FFmix never hides it, on purpose.

## Engine build

If [`engine/build-ffmpeg-lgpl-macos.sh`](engine/build-ffmpeg-lgpl-macos.sh) fails on your machine, open an issue with the relevant `build.log` tail and your macOS/Xcode versions. Reproducibility is a feature we maintain.

## Docs & translations

Typos, clarity fixes, and zh↔en consistency fixes are always welcome. The English docs are canonical; the [Chinese README](README.zh-CN.md) is maintained in lockstep.

## Licensing of contributions

By contributing you agree your contribution is licensed under the repo's licenses (MIT for code, CC BY 4.0 for prose).
