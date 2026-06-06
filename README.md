# quick-setup 文档站

本仓库是 `quick-setup` 的公开文档站仓库，最终发布在 [yuanboshe/quick-setup](https://github.com/yuanboshe/quick-setup)。站点内容位于 `docs/`，当前使用 VitePress 构建，并通过 GitHub Pages 发布到：

```text
https://qs.pz1.top/
```

QS 二进制文件通过 GitHub Release 发布；文档站负责说明下载方式、提供安装脚本，并分发 Agent skill 的 raw 文件。仓库仅承载公开文档、安装脚本和 Agent skill，不承载 QS 程序代码或构建流程。

## 本地开发

首次进入仓库后安装前端依赖：

```sh
npm install
```

启动本地开发服务：

```sh
npm run docs:dev
```

按终端输出访问本地预览地址，默认是：

```text
http://localhost:5173/
```

## 构建

构建文档站：

```sh
npm run docs:build
```

构建 GitHub Pages 完整产物，包括当前文档和版本索引中列出的历史版本快照：

```sh
npm run docs:build-pages
```

本地预览构建产物：

```sh
npm run docs:preview
```

`docs:preview` 使用 VitePress 默认端口 `4173`。如果该端口已有服务在运行，脚本会先停止占用端口的进程，再启动当前构建产物预览；需要保留已有进程时，使用 `npm run docs:preview -- --no-kill-port`。

## 安装脚本回归测试

修改 `scripts/install.sh` 后运行：

```sh
npm run test:install
```

该测试覆盖本机 release 资产目录安装，以及 `QS_INSTALL_TARGET` 远程安装模式下上传本地安装脚本和目标二进制的行为。安装脚本新增入口变量或改变资产来源规则时，应同步扩展该测试。

## 发布资产

- CLI 下载文件：[GitHub Releases](https://github.com/yuanboshe/quick-setup/releases)
- SHA256 校验文件：随 GitHub Release 发布
- 安装脚本真源：`scripts/install.sh`
- 下载说明页：`docs/download/index.md`
- 文档版本索引：`versions.json`
- Agent skill 真源：`skills/qs-cmd/SKILL.md`、`skills/qs-repo/SKILL.md`
- Agent skill 说明页：`docs/skills/index.md`

`versions.json` 中的 `current` 表示当前稳定文档对应的 QS 版本。站点根路径 `/` 始终发布当前稳定文档；历史版本由发布流程从对应 `vX.Y.Z` tag 构建到 `/versions/<version>/`。该 tag 同时也是 GitHub Release 的下载锚点，不再维护 `docs-v*` 这类独立文档 tag。不要把历史版本源码拷贝到当前分支。

`docs/public/install.sh`、`docs/public/versions.json` 和 `docs/public/skills/` 由 `npm run sync-public` 从上述真源生成，用于 GitHub Pages 静态发布，不作为可手工维护的事实源提交。

本地测试 GitHub Pages 静态发布路径：

```sh
npm run serve-public
```

该命令会先同步 `docs/public/install.sh` 和 `docs/public/skills/`，再启动本地静态服务，并打印一条使用 `_tmp/qs-install` 作为安装目标的 `curl ... | bash` 测试命令。

如果要连 Release 资产下载也完全走本地服务，可以把 `qs-<os>-<arch>` 和 `SHA256SUMS` 放到某个本地静态目录，并在测试命令中设置 `QS_RELEASE_BASE_URL` 指向该目录。

安装脚本默认从 GitHub Release 下载资产，并设置 curl 超时和重试。发布方可以在脚本中内置 GHX Worker、自建转发服务或 Release 镜像；自建转发服务面向公开安装脚本时应通过可信 owner 白名单免 token，不应开放通用免 token 转发。
