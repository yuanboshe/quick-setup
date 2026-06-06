# CLI 命令手册

QS 的命令设计围绕三件事：理解输入、生成可审查脚本、在明确需要时执行并留下记录。

## 命令总览

```text
qs inspect [input] [template-id] [--json] [--platform <value>] [--shell <value>]
qs render [recipe-input] -o <script>
qs run [recipe-input]
qs last [--json]
qs clean [--dry-run]
qs ghx get <github-url> [-o <path>] [--force] [--json]
qs ghx cat <github-url>
qs ghx doctor [--json]
qs version
qs export-example <path>
qs serve
qs completion <bash|zsh|fish|powershell>
```

根命令 `qs` 只显示帮助。需要诊断加载过程时，使用全局 `--verbose`，加载细节会写入 stderr。

`completion` 输出 shell 补全脚本。安装脚本默认会为 bash 安装补全；手动生成时可执行：

```sh
qs completion bash
```

## 输入推断

`inspect` 用来理解资产，会尽量根据输入推断类型：

1. 未传输入时，检查当前目录作为 repo。
2. 本地目录作为 repo。
3. 本地 `.yaml` / `.yml` 文件作为 recipe。
4. GitHub repo URL 或根 tree URL 作为 repo。
5. GitHub blob/raw recipe 文件 URL 作为 recipe。
6. `git+<git-url>.git[@ref]` 作为 repo。
7. `git+<git-url>.git[@ref]//<recipe-path>` 作为 recipe。
8. 其他 HTTP(S) URL 作为 recipe file source。
9. 单个非路径、非 source 参数作为当前目录 repo 下的 template ID。
10. `[input] [template-id]` 先解析 input，再在对应 repo 或 recipe 上下文中检查 template。

```sh
qs inspect
qs inspect ./example-repo
qs inspect ./example-repo/recipe.yaml --json
qs inspect https://github.com/yuanboshe/qs-repo/tree/devel --json
qs inspect https://github.com/yuanboshe/qs-repo/blob/example-repo/recipe.yaml --json
qs inspect ./example-repo repo-name/component1_simple/hello.sh --json
```

`render` 和 `run` 只接受 recipe 语义输入：

1. 未传输入时，读取当前目录下的 `recipe.yaml`。
2. 本地目录读取目录下的 `recipe.yaml`。
3. 本地文件直接作为 recipe。
4. GitHub repo URL、根 tree URL 或 `git+<git-url>.git[@ref]` 下载 repo 后读取根目录 `recipe.yaml`。
5. GitHub blob/raw 文件 URL、其他 HTTP(S) URL 或 `git+...//<recipe-path>` 读取指定 recipe。

```sh
qs render ./recipe.yaml -o ./quick-setup.sh
qs render ./example-repo -o ./quick-setup.sh
qs render https://github.com/yuanboshe/qs-repo/tree/devel -o ./quick-setup.sh
qs run https://github.com/yuanboshe/qs-repo/blob/example-repo/recipe.yaml
```

GitHub tree 子目录当前不作为 repo root 支持；需要把 recipe 放在 repo 根，或使用 GitHub blob/raw recipe 文件 URL、`git+...//<recipe-path>`。

## inspect

检查 repo 能力：

```sh
qs inspect
qs inspect ./example-repo
qs inspect https://github.com/yuanboshe/qs-repo/tree/devel --json
qs inspect ./example-repo --platform ubuntu --shell bash --json
```

repo 场景输出 repo 路径、来源、resolved commit 和可用 template 列表。`--platform` 按 `metadata.platform` 字符串包含过滤，`--shell` 按 `metadata.shell` 精确过滤。

检查 recipe 计划：

```sh
qs inspect ./recipe.yaml
qs inspect ./recipe.yaml --json
qs inspect https://github.com/owner/repo/blob/main/recipe.yaml --json
```

recipe 场景会严格校验 `qs.templates` 和 recipe 参数覆盖。template ID 写错、缺少上下文、template 目录或文件不存在、参数名无法匹配适用 template 时，命令会失败并输出具体错误。

检查单个 template：

```sh
qs inspect repo-name/component/install.sh
qs inspect ./example-repo repo-name/component1_simple/hello.sh --json
qs inspect ./recipe.yaml repo-name/component/install.sh --json
```

template 场景输出 description、metadata、参数默认值、最终值、源码路径和参与合并的 `config.yaml` 路径。

## 生成脚本

```sh
qs render ./recipe.yaml -o ./quick-setup.sh
```

`render` 使用与 recipe 场景 `inspect` 相同的解析和校验逻辑。输出路径会转成绝对路径，生成脚本会设置为可执行。

## 执行生成内容

```sh
qs run ./recipe.yaml
qs run ./recipe.yaml --record-dir ./runs
qs run ./recipe.yaml --no-record
```

`run` 会生成脚本文件，再通过 `bash <script.sh>` 执行。Windows 下默认优先使用 Git for Windows 的 Git Bash；如需指定执行器，可设置 `QS_BASH`。

默认会保存运行记录。`--record-dir <dir>` 指定单次记录目录，`--no-record` 关闭记录。

## clean

```sh
qs clean --dry-run
qs clean
```

`clean` 删除 `repos`、`files` 和 `ghx` 三类资产缓存，不删除 `runs` 运行记录和 `config` 配置。没有明确清理意图时，先使用 `--dry-run`。

## GHX GitHub 访问

QS 内置 GHX SDK，不要求用户安装外部 `ghx` 二进制。GitHub recipe、repo、framework 和 file source 会自动通过 GHX provider fallback 访问。

生成脚本默认启用 GHX runtime shim。脚本运行期间，常见 GitHub `curl` / `wget` 下载会转为 `qs ghx get/cat`；非 GitHub URL 保持原始 `curl` / `wget` 行为。需要关闭时，在 recipe 中设置：

```yaml
qs:
  ghx: false
```

诊断 GHX provider 配置：

```sh
qs ghx doctor
qs ghx doctor --json
```

手动下载或输出 GitHub 资源：

```sh
qs ghx get https://raw.githubusercontent.com/owner/repo/main/file.sh
qs ghx get https://raw.githubusercontent.com/owner/repo/main/file.sh -o file.sh
qs ghx get https://raw.githubusercontent.com/owner/repo/main/file.sh -o file.sh --force
qs ghx cat https://raw.githubusercontent.com/owner/repo/main/file.sh
```

`qs ghx get` 省略 `-o` 时，由 GHX SDK 推导默认输出文件名并写入当前目录；需要改名或写入其他目录时，传 `-o <path>`。输出文件已存在时，GHX SDK 返回 `output_exists`，QS 会以错误退出，不会发起网络下载；需要明确覆盖时传 `--force`。

QS 使用 GHX embedded profile，配置读取：

```text
~/.qs/config/ghx.yaml
当前工作目录下的 .qs/ghx.yaml
当前工作目录下的 ghx.yaml
```

## 最近运行记录

```sh
qs last
qs last --json
```

`last` 读取默认全局运行日志目录中的最近一次记录。`last --json` 输出紧凑摘要，包含状态、退出码、时间、输入、执行器、脚本路径和日志路径。

## 其他命令

输出版本：

```sh
qs version
```

导出内置示例仓库：

```sh
qs export-example ./
```

启动本地 HTTP demo server：

```sh
qs serve
```

`serve` 当前固定监听 `127.0.0.1:8000`。

## 安全建议

- 默认先 `inspect`，再 `render`，最后才考虑 `run`。
- 审查生成脚本后，只有明确需要执行时才 `run`。
- 涉及 `sudo`、系统目录、服务重启、远程来源或网络下载时，先确认 template 元数据和脚本内容。
- Agent 需要解析命令结果时，优先使用 `--json`。
- 诊断解析过程时用 `--verbose`，不要把 stderr 诊断信息当作 JSON 主体。
