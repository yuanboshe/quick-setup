---
name: qs-command
description: "Use when invoking, documenting, or reasoning about quick-setup CLI commands, including qs inspect, qs render, qs run, qs last, direct GitHub repo/tree/file URLs, git+ inputs, JSON output, and Agent-safe execution workflows."
---

# QS Command

使用 quick-setup（QS）命令时，把 QS 当作 shell 安装流程的组件发现器、脚本生成器和执行记录器。优先让用户和 Agent 看清楚 repo 提供哪些 template、recipe 会组合哪些 template、最终会生成什么脚本。

## 基本流程

1. 先用 `inspect` 理解 repo、recipe 或 template。
2. 再用 `render` 生成可审查脚本。
3. 只有在用户明确要求执行，或任务目标必须执行时，才用 `run`。
4. 执行后用 `last` 查看运行摘要，并按需读取脚本和日志路径。

Agent 需要解析命令结果时，优先使用 `--json`。人类阅读时，使用默认文本输出。

## 命令选择

```sh
qs inspect [input] [template-id] [--json] [--platform <value>] [--shell <value>]
qs render [recipe-input] -o <script>
qs run [recipe-input]
qs last [--json]
qs clean [--dry-run]
qs ghx get <github-url> -o <path> [--json]
qs ghx cat <github-url>
qs ghx doctor [--json]
qs serve
qs version
qs export-example <path>
qs completion <bash|zsh|fish|powershell>
```

根命令 `qs` 只用于显示帮助；执行动作时使用明确子命令。

需要诊断加载过程时，加全局 `--verbose`：

```sh
qs --verbose inspect ./recipe.yaml
qs --verbose render ./recipe.yaml -o ./quick-setup.sh
```

## 输入推断

`inspect` 用来理解资产，尽量根据输入推断类型：

- 不传输入：检查当前目录作为 repo。
- 本地目录：检查该目录作为 repo。
- 本地 `.yaml` / `.yml` 文件：检查 recipe。
- GitHub repo URL 或根 tree URL：检查 repo，例如 `https://github.com/owner/repo`、`https://github.com/owner/repo/tree/main`。
- GitHub blob/raw 文件 URL：检查 recipe。
- `git+<git-url>.git[@ref]`：检查 repo。
- `git+<git-url>.git[@ref]//<recipe-path>`：检查 recipe。
- 其他 HTTP(S) URL：作为 recipe file source 检查。
- 单个参数如果不是已存在路径、Git source 或 file source：视为当前目录 repo 下的 template ID。
- `[input] [template-id]`：先解析 input，再在对应 repo 或 recipe 上下文中检查 template。

`render` 和 `run` 只接受 recipe 语义输入：

- 不传输入：读取当前目录 `recipe.yaml`。
- 本地目录：读取目录下 `recipe.yaml`。
- 本地文件：直接作为 recipe。
- GitHub repo URL、根 tree URL 或 `git+<git-url>.git[@ref]`：下载 repo 后读取根目录 `recipe.yaml`。
- GitHub blob/raw 文件 URL、其他 HTTP(S) URL 或 `git+...//<recipe-path>`：读取指定 recipe。

GitHub tree 子目录当前不作为 repo root 支持；需要把 recipe 放在 repo 根，或使用 GitHub blob/raw recipe 文件 URL、`git+...//<recipe-path>`。

## 远程输入

Git source 支持：

```text
git+<git-url>.git
git+<git-url>.git@<ref>
git+<git-url>.git@<ref>//<recipe-path>
```

- `<ref>` 可以是 branch、tag 或 commit SHA；为空时使用远程默认分支 HEAD。
- `<recipe-path>` 必须是 repo 内相对路径，不能使用绝对路径或 `..` 越界。
- Git URL 必须带 `.git`，避免和 SSH 地址、Windows 路径、recipe 路径分隔产生歧义。
- GitHub Git source 内置走 GHX SDK 获取 archive snapshot，不要求用户额外安装 `ghx` 二进制；非 GitHub Git source 仍依赖本机 `git`。
- 需要精确表达非 GitHub Git、SSH/private repo、显式 ref 或 repo 内 recipe 路径时使用 `git+`；普通 GitHub 页面链接可以直接传给 QS。

HTTP(S) file source 支持：

```text
https://example.com/path/to/recipe.yml
https://example.com/path/to/
https://github.com/owner/repo/blob/ref/recipe.yaml
https://raw.githubusercontent.com/owner/repo/ref/recipe.yaml
```

- URL 路径为空或以 `/` 结尾时默认尝试 `recipe.yaml`。
- URL 明确指定文件名时，文件名不要求是 `recipe.yaml`。
- GitHub repo 内 recipe 文件 URL 优先复用已缓存的同 repo/ref snapshot；未命中时先下载 recipe 单文件，如果 recipe 省略 `qs.repos`，或包含相对 `repos[].path`、`repos[].path: .`、相对 `qs.framework`，则继续下载完整 repo snapshot。只有使用 repo snapshot 时，`repos[].path: .` 才表示该 repo snapshot 根目录。
- HTTP(S) file source 是文件资产输入，不表示直接执行远程 shell 文本。

使用远程输入时，优先 pin 到 tag 或 commit SHA。使用 floating branch 或默认 HEAD 时，在回复中说明结果会随远端变化。

## Inspect

检查 repo 能力：

```sh
qs inspect
qs inspect ./resource/example-repo
qs inspect https://github.com/yuanboshe/qs-repo/tree/devel --json
qs inspect ./resource/example-repo --platform ubuntu --shell bash --json
```

repo 场景输出 repo 路径、来源、resolved commit 和可用 template 列表。`--platform` 按 `metadata.platform` 字符串包含过滤，`--shell` 按 `metadata.shell` 精确过滤；未声明对应元数据的 template 不会匹配过滤条件。

检查 recipe 计划：

```sh
qs inspect ./recipe.yaml
qs inspect https://github.com/owner/qs-repo/blob/main/recipe.yaml --json
```

recipe 场景会校验 `qs.templates` 和 recipe 参数覆盖。template ID 写错、缺少上下文、template 目录或文件不存在、参数名未声明时，命令会失败并输出具体错误。

检查单个 template：

```sh
qs inspect repo/component/install.sh
qs inspect ./resource/example-repo example-repo/component1_simple/hello.sh --json
qs inspect ./recipe.yaml repo-name/component/install.sh --json
```

template 场景输出 description、metadata、参数默认值、最终值、源码路径和参与合并的 `config.yaml` 路径。Agent 应用 metadata 判断目标系统、解释器、依赖、权限副作用和网络风险。

warning、error 和 `--verbose` 诊断信息写入 stderr，不应混入 JSON 业务结果。

## 生成和执行

生成脚本：

```sh
qs render ./recipe.yaml -o ./quick-setup.sh
qs render ./resource/example-repo -o ./quick-setup.sh
qs render https://github.com/yuanboshe/qs-repo/tree/devel -o ./quick-setup.sh
qs render https://github.com/owner/qs-repo/blob/main/recipe.yaml -o ./quick-setup.sh
```

`render` 使用与 recipe 场景 `inspect` 相同的严格校验；不要把 stderr 中没有报错但脚本缺少片段作为正常结果处理。

直接执行生成内容：

```sh
qs run ./recipe.yaml
qs run https://github.com/yuanboshe/qs-repo/tree/devel
qs run ./recipe.yaml --record-dir ./runs
qs run ./recipe.yaml --no-record
```

`run` 通过 `bash <script.sh>` 执行生成脚本。Windows 下默认使用 Git for Windows 的 Git Bash，不使用 WSL bash；如果 Git Bash 不在默认安装路径，可用 `QS_BASH` 指定 `bash.exe`。默认会把运行记录保存到 QS 全局运行日志目录，包括解析计划、生成脚本、执行器、stdout、stderr 和结果摘要。默认目录是 `~/.qs/runs`；`QS_HOME` 会改为 `$QS_HOME/runs`；`QS_RUNS_DIR` 可直接指定目录。`--record-dir <dir>` 覆盖单次记录目录；`--no-record` 关闭记录，并使用临时脚本文件执行。

查看最近一次默认运行记录：

```sh
qs last
qs last --json
```

清理远程资产缓存：

```sh
qs clean --dry-run
qs clean
```

`clean` 删除 `repos`、`files` 和 `ghx` 三类缓存，不删除 `runs` 运行记录和 `config` 配置。

## GHX 增强

QS 内置 GHX SDK。使用 GitHub source 时，QS 会自动通过 GHX provider fallback 访问 GitHub，不要求用户安装 `ghx` 二进制。QS 使用 GHX embedded profile，不读取或创建独立 `~/.ghx/config.yaml`。GHX 的 Worker、自建转发服务、token header 和 provider 顺序由 QS 的 GHX 配置控制：

```text
~/.qs/config/ghx.yaml
当前工作目录下的 .qs/ghx.yaml
当前工作目录下的 ghx.yaml
```

`qs.ghx` 默认开启。开启时，生成脚本头部会注入 runtime shim，在脚本运行期间接管 GitHub URL 的常见 `curl` / `wget` 下载形态，并转为 `qs ghx get/cat`。非 GitHub URL 继续走系统原始 `curl` / `wget`。如需关闭：

```yaml
qs:
  ghx: false
```

深度诊断或手动测试时使用：

```sh
qs ghx doctor
qs ghx get https://raw.githubusercontent.com/owner/repo/main/file.sh -o file.sh
qs ghx cat https://raw.githubusercontent.com/owner/repo/main/file.sh
```

默认缓存目录：

- `~/.qs/repos`：组件库完整源码快照，不保留 `.git`。
- `~/.qs/files`：recipe/framework 单文件缓存。
- `~/.qs/ghx`：GHX 字节缓存。

## 安全约束

- 默认先 `inspect`，再 `render`，最后才考虑 `run`。
- 涉及 `sudo`、安装软件、修改系统目录、服务重启、远程 repo 或网络下载时，先说明将使用的输入、template 和主要风险。
- 当流程具备复用价值时，执行后应把经验沉淀为 component/template/recipe，而不是只保留一次性命令。
- 目标系统明确时，先检查 template 元数据是否匹配；当前 QS 只输出元数据，不自动拒绝不匹配 template。
- 不要为了省步骤跳过可审查脚本；除非用户明确要求直接运行。
- 执行失败时，优先用 `qs last --json` 找到执行器、脚本、stdout、stderr 和结果摘要，再判断下一步。
- 不要宣称未实现的命令或 flag 可用；如果命令不存在，按实际错误向用户说明。
