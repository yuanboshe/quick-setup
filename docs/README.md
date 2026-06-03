# quick-setup

quick-setup 是一个用 Go 编写的本地 CLI，用 `recipe + repo/component/template + framework` 生成普通 shell 脚本，并可在明确需要时直接执行生成内容。

它的核心目标是把一次性的 shell 操作沉淀为可复用、可解释、可审查、可追踪的脚本资产，同时保持低学习成本和普通 shell 可读性。

## 适用场景

- 管理多段安装、配置、诊断脚本，并希望按功能复用。
- 为不同机器或项目组合相同 template，只在 recipe 中覆盖参数。
- 在执行前审查生成脚本，降低远程来源、系统修改和高权限操作的风险。
- 让 Agent 先理解 recipe、repo、template 和参数，再生成脚本、记录执行结果。

## 当前能力

当前 CLI 已支持：

- `render`：根据 recipe 生成脚本文件。
- `run`：生成脚本并通过 `bash <script.sh>` 执行。
- `explain`：解释 recipe 解析后的 repo、framework、template 和最终参数。
- `list templates`：列出 recipe 声明 repo 中的可用 template。
- `inspect template`：查看单个 template 的说明、参数、元数据和来源路径。
- `last`：查看最近一次默认运行记录。
- `repo fetch`、`repo list`、`repo clean`：管理 Git repo 缓存。
- `version`：输出版本号。
- `export-example`：导出内置示例仓库。
- `serve`：启动本地 HTTP demo server。

默认入口文件名是 `recipe.yaml`。`config.yaml` 只用于 repo 根目录或 template 目录中的默认上下文文件，包含 `args` 和 `metadata`。

## 安全使用路径

推荐流程是：

1. 先用 `explain`、`list templates`、`inspect template` 理解输入、template 和参数。
2. 再用 `render` 生成脚本，并人工审查脚本内容。
3. 只有在明确需要执行时，才使用 `run`。
4. 执行后用 `last` 查看运行摘要，并按记录路径读取脚本和日志。

远程 Git source 和 HTTP(S) file source 会先缓存到本地，再按本地文件或 repo 解析；QS 不支持直接执行远程 shell 文本。

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
