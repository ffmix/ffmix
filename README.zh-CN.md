<div align="center">

# FFmix

**macOS 原生的 FFmpeg 图形界面 —— 你看到的命令，就是实际执行的命令。**

[官网](https://ffmix.com) · [工作原理](docs/how-it-works.md) · [FFmpeg 配方与天坑](docs/ffmpeg-recipes.md) · [开发日志](devlog/) · [English README](README.md)

</div>

---

FFmix 是一款 macOS 原生媒体处理工具：拖入视频/音频/图片 → 选任务（或用一句话描述）→ 审阅管线 → 执行。每个任务都是一个真实的本地 `ffmpeg` 进程 —— 而且确切的命令始终可见、可编辑、可复制。

我们正在 build in public。这个仓库是 FFmix 在 GitHub 上的开放主页：

| 内容 | 为什么 |
|---|---|
| [**FFmpeg 配方与天坑**](docs/ffmpeg-recipes.md) | FFmix 生成的每条命令，都在真实文件上验证过 —— 包括我们踩过的坑（静默空操作、构建差异、版本破坏性变更）。就算你不用 FFmix，这份文档也独立有用。 |
| [**FFmix 工作原理**](docs/how-it-works.md) | 架构设计：ffmpeg 之上的**翻译层**，而不是把它藏起来的封装层。 |
| [**原生技术栈**](docs/native-stack.md) | SwiftUI、AVFoundation、VideoToolbox、`Process` + POSIX 信号、whisper.cpp —— 一个纯正 Mac 应用如何驱动 ffmpeg。 |
| [**macOS 的 LGPL ffmpeg 构建**](engine/) | 产出 FFmix 内置引擎的完整脚本：静态 LGPL ffmpeg 7.1（VideoToolbox + libass + whisper.cpp/Metal），Apple Silicon，可复现、可上架 App Store。 |
| [**与同类工具的比较**](docs/comparison.md) | 诚实地对比 HandBrake、FFmpegFreeUI、ffmpeg-kit 等 —— 包括哪些情况下你**不该**用 FFmix。 |
| [**开发日志**](devlog/) | build in public 笔记：决策、弯路、数据。 |
| [**Issues**](../../issues) | FFmix 应用的公开 bug 跟踪与功能请求。 |

## 三条产品契约

FFmix 的一切都被三条承诺约束：

1. **全程本地处理。** 媒体文件永远不离开你的 Mac。所有处理都是本地 `ffmpeg` / `whisper.cpp` 子进程。唯一可能联网的是可选的 AI 功能 —— 它只发送一句文本，永远不发送文件。
2. **AI 管线未经确认绝不执行。** 用自然语言描述任务后，生成的管线逐步展示 —— 可编辑、可删除 —— 在你确认之前什么都不会运行。
3. **展示的命令 == 执行的命令。** 界面里的每一条命令字符串，就是交给引擎的字面字符串。没有隐藏参数，没有"简化视图"。随时可以切换到手动模式直接编辑原始命令。

任何违反这三条的功能都不会上线。

## 为什么还要再做一个 ffmpeg GUI？

ffmpeg 几乎无所不能，但几乎没人记得住用法。现有方案各有牺牲：

- **在线转换工具** —— 把文件上传到别人的服务器。慢、限大小，隐私上不可接受。
- **单一用途的小工具** —— 压缩一个 app、做 GIF 一个 app、加字幕又一个 app。
- **把命令藏起来的封装** —— 没出错时都好，一出错就是在调试黑盒。

FFmix 的定位：**翻译层，不是黑盒**。GUI 构建真实的 ffmpeg 命令并展示给你。你可以多年不读 man page 地用它，也可以把它当作学 ffmpeg 最快的方式 —— 复制任何生成的命令到你自己的终端。

## 当前状态

FFmix 正在为 **macOS 14+（Apple Silicon）** 积极开发中，2026 年内发布。关注方式：

- ⭐ Star 本仓库，跟进开发日志
- 🌐 [ffmix.com](https://ffmix.com) —— 产品官网与发布动态
- 🐛 [Issues](../../issues) —— 欢迎 bug 报告与功能请求

## FFmix 开源吗？

FFmix 应用本体是商业产品（买断制）。本仓库中开放的部分：

- **引擎构建脚本**（LGPL 合规 —— 你可以逐字复现我们的内置 ffmpeg，甚至替换成自己构建的版本），
- 全部**文档、配方、开发日志**，
- **issue 跟踪**。

我们认为这才是"本地优先"的诚实版本：你可以验证处理你文件的二进制到底是什么、执行的命令到底是哪条。

## 致谢

FFmix 站在 FFmpeg、whisper.cpp、libass 等一长串开源巨人的肩膀上。见 [ACKNOWLEDGMENTS.md](ACKNOWLEDGMENTS.md) —— 包括我们如何履行 LGPL 义务、如何自行重新链接引擎。

## 许可证

- 本仓库代码（构建脚本、片段）：[MIT](LICENSE)
- 文档与开发日志文本：[CC BY 4.0](https://creativecommons.org/licenses/by/4.0/)
- FFmix 应用为专有软件。FFmpeg 等引擎组件保持各自原许可证 —— 见 [engine/THIRD-PARTY.md](engine/THIRD-PARTY.md)。
