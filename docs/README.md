# quick-setup

quick-setup（QS）是一个本地 CLI，用 `recipe + repo/component/template + framework` 生成普通 shell 脚本。它适合把安装、配置、诊断这类一次性 shell 操作沉淀成可复用、可解释、可审查、可追踪的脚本资产。

## 3 分钟跑起来

Linux 用户直接安装：

```sh
curl -fsSL https://qs.pz1.top/install.sh | bash
```

导出内置示例仓库，先解释，再生成脚本：

```sh
qs export-example ./
qs explain ./example-repo
qs render ./example-repo -o ./quick-setup.sh
```

确认脚本内容符合预期后再执行：

```sh
qs run ./example-repo
qs last
```

这就是 QS 的最小使用闭环：`explain -> render -> run -> last`。

## 关键能力

- `explain`：看清 recipe 会加载哪些 repo、framework、template 和参数。
- `render`：生成可审查 shell 脚本。
- `run`：执行生成脚本并保存运行记录。
- `last`：查看最近一次运行摘要和日志路径。
- `list templates` / `inspect template`：发现和检查 template。
- `repo fetch/list/clean`：管理远程 Git repo 缓存。
- `qs ghx get/cat/doctor`：诊断或手动使用内置 GHX GitHub 访问能力。

GitHub 远程来源内置走 GHX SDK。生成脚本默认启用 GHX runtime shim，常见 GitHub `curl` / `wget` 下载会自动通过 GHX provider fallback 访问；需要保留原始网络行为时，在 recipe 中设置 `qs.ghx: false`。

默认入口文件名是 `recipe.yaml`。`config.yaml` 只用于 repo 或 template 目录中的默认上下文文件，包含 `args` 和 `metadata`。

远程 Git source 和 HTTP(S) file source 会先缓存到本地，再按本地文件或 repo 解析；QS 不把普通远程 shell 文本当作脚本直接执行。

## 文档入口

- [快速开始](quickstart/quickstart.md)
- [核心概念](quickstart/concept.md)
- [CLI 命令手册](manual/cli.md)
- [recipe 手册](manual/recipe.md)
- [template 手册](manual/template.md)
- [template config 手册](manual/template-config.md)
- [repo 与 component 手册](manual/repo-component.md)
- [framework 手册](manual/framework.md)
- [远程来源与缓存](manual/remote-source-cache.md)
- [运行记录](manual/run-record.md)
- [Agent 协作流程](manual/agent-workflow.md)

## 反馈

问题和建议可以提交到 [quick-setup issues](https://github.com/yuanboshe/quick-setup/issues)。
