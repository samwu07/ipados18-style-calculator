# iPadOS18StyleCalculator IPA 打包说明

当前环境没有 Xcode，因此这里提供的是可打包工程、Mac 打包脚本，以及 GitHub Actions 云端打包配置。

## GitHub Actions 方式

这个方式适合 TrollStore 实机测试，不需要 Apple 证书。

1. 新建一个 GitHub 仓库。
2. 把本目录里的所有文件上传到仓库根目录，确保 `.github/workflows/build-trollstore-ipa.yml` 也上传成功。
3. 打开仓库的 Actions 页面。
4. 选择 `Build TrollStore IPA`。
5. 点击 `Run workflow`。
6. 构建完成后，在页面底部 Artifacts 下载 `iPadOS18StyleCalculator-TrollStore-IPA`。
7. 解压得到 `iPadOS18StyleCalculator-TrollStore.ipa`，传到 iPad 后用 TrollStore 打开安装。

## 打包步骤

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

- 真机侧载需要 Apple 开发者签名或侧载工具重新签名。
- 免费 Apple ID 通常只能短期测试安装。
- 如果用 AltStore、Sideloadly、爱思助手等工具，仍然需要有效签名流程。
