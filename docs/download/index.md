# 下载 quick-setup

当前发布版本：`v0.3.0`

程序文件和校验文件发布在 GitHub Release：

```text
https://github.com/yuanboshe/quick-setup/releases/tag/v0.3.0
```

## Linux 一行安装

```sh
curl -fsSL https://qs.pz1.top/install.sh | bash
qs version
```

## 平台文件

Release 页面包含 Linux、macOS、Windows 的 `amd64` / `arm64` 二进制，以及对应的 `SHA256SUMS` 校验文件。优先从 Release 页面选择与你系统匹配的文件。

## 安装脚本

安装脚本由文档站提供，二进制和 `SHA256SUMS` 从 GitHub Release 下载。推荐直接运行：

```sh
curl -fsSL https://qs.pz1.top/install.sh | bash
```

安装脚本会为下载请求设置连接超时、总超时和重试，避免 GitHub 无法访问时长时间卡住。发布方可以在脚本中内置 GHX Worker、自建转发服务或 Release 镜像；配置后，用户不需要额外传参数。

如果你在测试自己的 GHX 兼容转发服务或 Cloudflare Worker，可以临时设置 `QS_GHX_BASE_URL`。转发入口格式应为 `<base>?url=<escaped GitHub URL>`。

```sh
curl -fsSL https://qs.pz1.top/install.sh | QS_GHX_BASE_URL="https://ghx-cache.example.com/" bash
```

多个转发入口可以用空格或逗号传给 `QS_GHX_BASE_URLS`，脚本会按顺序尝试：

```sh
curl -fsSL https://qs.pz1.top/install.sh | QS_GHX_BASE_URLS="https://worker.example.com/,https://ghx-cache.example.com/" bash
```

不建议在公开安装命令里携带自建转发 token。更好的方式是在自建转发服务端只对 QS 安装所需的公开 release 资产设置免 token 白名单，其他 GitHub URL 仍然要求 token。

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
