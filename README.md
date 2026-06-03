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

本地预览构建产物：

```sh
npm run docs:preview
```

`docs:preview` 使用 VitePress 默认端口 `4173`。如果该端口已有服务在运行，脚本会提示预览地址并退出成功；如果不是文档预览服务，先停止占用该端口的进程再重新执行。

## 发布资产

- CLI 下载文件：[GitHub Releases](https://github.com/yuanboshe/quick-setup/releases)
- SHA256 校验文件：随 GitHub Release 发布
- 安装脚本真源：`scripts/install.sh`
- 下载说明页：`docs/download/index.md`
- Agent skill 真源：`skills/qs-command/SKILL.md`、`skills/qs-repo/SKILL.md`
- Agent skill 说明页：`docs/skills/index.md`

`docs/public/install.sh` 和 `docs/public/skills/` 由 `npm run sync-public` 从上述真源生成，用于 GitHub Pages 静态发布，不作为可手工维护的事实源提交。

安装脚本默认从 GitHub Release 下载资产，并设置 curl 超时和重试。发布方可以在脚本中内置 GHX Worker、自建转发服务或 Release 镜像；自建转发服务面向公开安装脚本时应通过可信 owner 白名单免 token，不应开放通用免 token 转发。

更新版本时，需要同步检查 GitHub Release 资产、`SHA256SUMS`、`scripts/install.sh` 中的版本号、下载说明页和 skill 说明页。
