---
name: qs-command
description: "Use when invoking, documenting, or reasoning about quick-setup CLI commands, including qs render, qs run, qs explain, qs list templates, qs inspect template, qs last, repo cache commands, git+ inputs, JSON output, and Agent-safe execution workflows."
---

# QS Command

使用 quick-setup（QS）命令时，把 QS 当作 shell 安装流程的生成器和执行记录器。优先让用户和 Agent 看清楚“会生成什么、会执行什么、执行后留下什么记录”。

## 基本流程

1. 先用信息命令理解 recipe、repo、template 和参数。
2. 再用 `render` 生成可审查脚本。
3. 只有在用户明确要求执行，或任务目标必须执行时，才用 `run`。
4. 执行后用 `last` 查看运行摘要，并按需读取脚本和日志路径。

Agent 需要解析命令结果时，优先使用 `--json`。人类阅读时，使用默认文本输出。

## 命令选择

```sh
qs render <recipe|dir|git-source|file-source> -o <script>
qs run <recipe|dir|git-source|file-source>
qs explain <recipe|dir|git-source|file-source> [--json]
qs list templates <recipe|dir|git-source|file-source> [--json]
qs inspect template <recipe|dir|git-source|file-source> <template-id> [--json]
qs last [--json]
qs repo fetch <git-source>
qs repo list [--json]
qs repo clean [git-source|--all] [--dry-run]
qs serve
qs version
qs export-example <path>
```

根命令 `qs` 只用于显示帮助；执行动作时使用明确子命令。

需要诊断加载过程时，加全局 `--verbose`：

```sh
qs --verbose explain ./recipe.yaml
qs --verbose render ./recipe.yaml -o ./quick-setup.sh
```

## 输入规则

本地输入：

- 传入文件时，把该文件作为 `recipe`。
- 传入目录时，读取该目录下的 `recipe.yaml`。
- 不传输入时，读取当前目录下的 `recipe.yaml`。

远程 Git 输入：

```text
git+<git-url>.git
git+<git-url>.git@<ref>
git+<git-url>.git@<ref>//<recipe-path>
```

- `<recipe-path>` 为空时默认使用仓库内的 `recipe.yaml`。
- `<recipe-path>` 可以指向仓库内任意文件名，不要求文件名必须是 `recipe.yaml`。
- `<recipe-path>` 必须是 repo 内相对路径，不能使用绝对路径或 `..` 越界。
- `<ref>` 可以是 branch、tag 或 40 位 commit SHA；为空时使用远程默认分支 HEAD。
- Git URL 必须带 `.git`，避免和 SSH 地址、Windows 路径、recipe 路径分隔产生歧义。
- QS 会把远程 repo 先下载到本地 cache，再按本地 repo 解析。

远程文件输入：

```text
https://example.com/path/to/recipe.yml
https://example.com/path/to/
```

- HTTP(S) URL 可以作为 recipe file source。
- URL 路径为空或以 `/` 结尾时默认尝试 `recipe.yaml`。
- URL 明确指定文件名时，文件名不要求是 `recipe.yaml`。
- QS 会把远程文件先下载到本地 file cache，再按本地文件解析。
- HTTP(S) file source 是文件资产输入，不表示直接执行远程 shell 文本。

不要把 `curl | bash` 或未知远程脚本文本交给 QS 直接执行。

使用远程输入时，优先 pin 到 tag 或 commit SHA。使用 floating branch 或默认 HEAD 时，在回复中说明结果会随远端变化。

## 信息命令

解释 recipe 解析结果：

```sh
qs explain ./recipe.yaml
qs explain ./recipe.yaml --json
```

`explain` 会校验 `qs.templates` 中选中的 template 和 recipe 参数覆盖。template ID 写错、缺少上下文、template 目录或文件不存在、参数名未声明时，命令会失败并输出具体错误。

列出可用 template：

```sh
qs list templates ./recipe.yaml
qs list templates git+https://example.com/org/qs-repo.git@v1.0.0 --json
qs list templates ./recipe.yaml --platform ubuntu --shell bash --json
```

查看单个 template：

```sh
qs inspect template ./recipe.yaml repo-name/component/install.sh
qs inspect template ./recipe.yaml repo-name/component/install.sh --json
```

`--platform <value>` 按 `metadata.platform` 字符串包含过滤，`--shell <value>` 按 `metadata.shell` 精确过滤。template 如果没有声明对应元数据，不会匹配该过滤条件。

`list templates` 和 `inspect template` 是发现命令，面向 repo 中已有 template。它们不要求 recipe 的 `qs.templates` 或参数覆盖当前全部有效；当 `explain` 因选中 template 写错失败时，可以先用这两个命令确认可用 ID 和参数名。

`--json` 输出保持紧凑，适合 Agent 解析。template 如果声明了元数据，JSON 中会包含 `metadata.platform`、`metadata.shell`、`metadata.requires`、`metadata.effects` 和 `metadata.network`。Agent 在组织复杂流程时，应优先用这些字段判断目标系统、解释器、依赖、权限副作用和网络风险。

warning、error 和 `--verbose` 诊断信息写入 stderr，不应混入 JSON 业务结果。

## 生成和执行

生成脚本：

```sh
qs render ./recipe.yaml -o ./quick-setup.sh
qs render git+https://example.com/org/qs-repo.git@v1.0.0 -o ./quick-setup.sh
```

`render` 使用与 `explain` 相同的严格校验；不要把 stderr 中没有报错但脚本缺少片段作为正常结果处理。

直接执行生成内容：

```sh
qs run ./recipe.yaml
qs run git+https://example.com/org/qs-repo.git@v1.0.0
qs run ./recipe.yaml --record-dir ./runs
qs run ./recipe.yaml --no-record
```

`run` 通过 `bash <script.sh>` 执行生成脚本。Windows 下默认使用 Git for Windows 的 Git Bash，不使用 WSL bash；如果 Git Bash 不在默认安装路径，可用 `QS_BASH` 指定 `bash.exe`。默认会把运行记录保存到 QS 全局运行日志目录，包括解析计划、生成脚本、执行器、stdout、stderr 和结果摘要。默认目录是 `~/.qs/runs`；`QS_HOME` 会改为 `$QS_HOME/runs`；`QS_RUNS_DIR` 可直接指定目录。`--record-dir <dir>` 覆盖单次记录目录；`--no-record` 关闭记录，并使用临时脚本文件执行。

查看最近一次默认运行记录：

```sh
qs last
qs last --json
```

## Repo Cache

只下载远程组件仓库，不渲染、不执行：

```sh
qs repo fetch git+https://example.com/org/qs-repo.git@v1.0.0
```

查看 cache：

```sh
qs repo list
qs repo list --json
```

清理 cache：

```sh
qs repo clean git+https://example.com/org/qs-repo.git@v1.0.0
qs repo clean --all --dry-run
qs repo clean --all
```

`repo clean` 默认会删除匹配项。清理前先使用 `--dry-run`，除非用户已经明确要求执行清理。

## 安全约束

- 默认先 `explain` 或 `inspect template`，再 `render`，最后才考虑 `run`。
- 涉及 `sudo`、安装软件、修改系统目录、服务重启、远程 repo 或网络下载时，先说明将使用的输入、template 和主要风险。
- 当流程具备复用价值时，执行后应把经验沉淀为 component/template/recipe，而不是只保留一次性命令。
- 目标系统明确时，先检查 template 元数据是否匹配；当前 QS 只输出元数据，不自动拒绝不匹配 template。
- 不要为了省步骤跳过可审查脚本；除非用户明确要求直接运行。
- 执行失败时，优先用 `qs last --json` 找到执行器、脚本、stdout、stderr 和结果摘要，再判断下一步。
- 不要宣称未实现的命令或 flag 可用；如果命令不存在，按实际错误向用户说明。
