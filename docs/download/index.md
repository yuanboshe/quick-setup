# 下载 quick-setup

当前发布版本：`v0.2.0`

程序文件和校验文件发布在 GitHub Release：

```text
https://github.com/yuanboshe/quick-setup/releases/tag/v0.2.0
```

## 平台文件

Release 页面包含 Linux、macOS、Windows 的 `amd64` / `arm64` 二进制，以及对应的 `SHA256SUMS` 校验文件。优先从 Release 页面选择与你系统匹配的文件。

## 安装脚本

Linux 用户可以直接使用安装脚本。脚本由文档站提供，二进制和 `SHA256SUMS` 从 GitHub Release 下载。

```sh
curl -fsSL https://qs.pz1.top/install.sh | bash
```

如果下载 GitHub Release 需要代理前缀，把前缀作为第一个参数传入。脚本会把该前缀拼接到 Release 资产 URL 前面。

```sh
curl -fsSL https://qs.pz1.top/install.sh | bash -s -- https://example-proxy/
```

## 手动校验

下载二进制和 `SHA256SUMS` 后，在同一目录执行：

```sh
sha256sum -c SHA256SUMS --ignore-missing
```

其他系统使用同类 SHA256 工具，将输出值与 `SHA256SUMS` 中对应文件的 SHA256 值比对即可。
