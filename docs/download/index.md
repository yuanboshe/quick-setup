# 下载 quick-setup

当前发布版本：`v0.3.0`

程序文件和校验文件发布在 GitHub Release：

```text
https://github.com/yuanboshe/quick-setup/releases/tag/v0.3.0
```

## Bash 一行安装

```sh
curl -fsSL https://qs.pz1.top/install.sh | bash
```

## 平台文件

Release 页面包含 Linux、macOS、Windows 的 `amd64` / `arm64` 二进制，以及对应的 `SHA256SUMS` 校验文件。优先从 Release 页面选择与你系统匹配的文件。

## 安装脚本

安装脚本由文档站提供，二进制和 `SHA256SUMS` 从 GitHub Release 下载。当前支持 Linux，以及 Windows 上的 Git Bash、MSYS 和 Cygwin。推荐直接运行：

```sh
curl -fsSL https://qs.pz1.top/install.sh | bash
```

安装脚本会为下载请求设置连接超时、总超时和重试，避免 GitHub 无法访问时长时间卡住。当前脚本默认会按顺序尝试 GHX Worker `https://ghx-cache.pz1.top`、自建转发 `https://ghx.pz1.top` 和官方 GitHub。

安装完成后，脚本默认会安装 bash 命令补全。Linux 优先写入 `/etc/bash_completion.d/qs`，权限不足时写入用户 completion 目录；Windows Git Bash、MSYS 和 Cygwin 会写入 `~/.bash_completion.d/qs` 并更新 `~/.bashrc`。脚本会在安装完成后提示立即生效命令，通常是 `source <补全文件路径>`；打开新的 bash shell 后也会生效。需要关闭补全安装时：

```sh
curl -fsSL https://qs.pz1.top/install.sh | QS_INSTALL_COMPLETION=false bash
```

安装脚本默认也会安装 QS Agent skills 到 `${AGENTS_HOME:-~/.agents}/skills`，用于让 Agent 了解 QS 命令和组件库规范。检测到 Codex 或 Claude 的用户目录时，脚本会在对应 agent 的 skills 目录里创建引用；Windows 下会优先使用目录 junction。需要关闭 skill 安装时：

```sh
curl -fsSL https://qs.pz1.top/install.sh | QS_INSTALL_SKILLS=false bash
```

需要指定 skill 安装目录时：

```sh
curl -fsSL https://qs.pz1.top/install.sh | QS_SKILLS_DIR="/path/to/skills" bash
```

需要关闭自动 agent 目录引用时：

```sh
curl -fsSL https://qs.pz1.top/install.sh | QS_AGENT_SKILL_LINKS=false bash
```

如果你在测试自己的 GHX 兼容转发服务或 Cloudflare Worker，可以设置 `QS_GHX_BASE_URL`。转发入口格式应为 `<base>?url=<escaped GitHub URL>`。

```sh
curl -fsSL https://qs.pz1.top/install.sh | QS_GHX_BASE_URL="https://ghx-cache.pz1.top" bash
```

多个转发入口可以用空格或逗号传给 `QS_GHX_BASE_URLS`，脚本会按顺序尝试：

```sh
curl -fsSL https://qs.pz1.top/install.sh | QS_GHX_BASE_URLS="https://ghx-cache.pz1.top,https://ghx.pz1.top" bash
```

如果你已经把 Release 资产同步到自己的镜像目录，设置 `QS_RELEASE_BASE_URL`。该目录下需要包含 `qs-linux-amd64`、`qs-linux-arm64` 和 `SHA256SUMS` 等文件。

```sh
curl -fsSL https://qs.pz1.top/install.sh | QS_RELEASE_BASE_URL="https://mirror.example.com/quick-setup/v0.3.0/" bash
```

多个镜像目录可以用空格或逗号传给 `QS_RELEASE_BASE_URLS`。

仍然可以使用旧的代理前缀参数。脚本会把该前缀拼接到 GitHub Release 资产 URL 前面。

```sh
curl -fsSL https://qs.pz1.top/install.sh | bash -s -- https://example-proxy/
```

## 手动校验

下载二进制和 `SHA256SUMS` 后，在同一目录执行：

```sh
sha256sum -c SHA256SUMS --ignore-missing
```

其他系统使用同类 SHA256 工具，将输出值与 `SHA256SUMS` 中对应文件的 SHA256 值比对即可。
