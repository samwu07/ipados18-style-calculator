# iPadOS 18 Style Calculator for iPadOS 16

一个使用 SwiftUI 编写的 iPad 计算器，目标是在 **iPadOS 16 及以上系统** 上提供接近 iPadOS 18 原生计算器的界面体验，并加入科学计算和常用换算功能。项目支持通过 GitHub Actions 构建适用于 **TrollStore 实机测试** 的 unsigned IPA。

## 主要特性

- 支持 iPadOS 16+
- SwiftUI 原生界面，适配横屏、竖屏、分屏和台前调度
- 基础计算器界面接近 iPadOS 18 原生计算器风格
- 科学计算模式，支持三角函数、幂、根号、阶乘、常数和记忆键
- 更多页提供离线可用的单位换算和常用计算
- 计算结果支持每三位分隔显示
- 可通过 GitHub Actions 自动打包 TrollStore IPA

## 适用设备

- iPadOS 16 或更新版本
- iPad 真机测试建议使用 TrollStore 环境安装 IPA

## GitHub Actions 打包

这个方式适合 TrollStore 实机测试，不需要 Apple 证书。

1. 打开仓库的 Actions 页面。
2. 选择 `Build TrollStore IPA`。
3. 点击 `Run workflow`，或等待 push 后自动构建。
4. 构建完成后，在页面底部 Artifacts 下载 `iPadOS18StyleCalculator-TrollStore-IPA`。
5. 解压得到 `iPadOS18StyleCalculator-TrollStore.ipa`。
6. 把 IPA 传到 iPad 后，用 TrollStore 打开安装。

## Release 下载

也可以把构建好的 `iPadOS18StyleCalculator-TrollStore.ipa` 上传到 GitHub Releases，用户就能直接从 Release 页面下载，不必进入 Actions 找 artifact。

## Mac 本地打包

如果需要用 Apple 开发者签名在本地打包：

1. 在 Mac 上安装 Xcode，并登录 Apple ID。
2. 打开 `iPadOS18StyleCalculator.xcodeproj`。
3. 在 Signing & Capabilities 里选择你的 Team。
4. 如果 Bundle ID 已被占用，把 `com.codex.ipados18stylecalculator` 改成你自己的唯一 ID。
5. 在终端运行：

```bash
chmod +x package_ipa_macos.sh
./package_ipa_macos.sh YOUR_APPLE_TEAM_ID
```

生成的 IPA 会在：

```text
build/export/iPadOS18StyleCalculator.ipa
```

## 注意

- TrollStore 安装适合实机测试 unsigned IPA。
- 普通侧载工具仍然需要有效签名流程。
- GitHub Actions artifact 会过期，长期分发建议使用 Release 附件。
