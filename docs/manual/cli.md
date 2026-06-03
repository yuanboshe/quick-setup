# CLI 命令手册

QS 的命令设计围绕三件事：理解输入、生成可审查脚本、在明确需要时执行并留下记录。

## 命令总览

```text
qs render [recipe file|recipe dir|git source|file source] -o <script>
qs run [recipe file|recipe dir|git source|file source]
qs explain [recipe file|recipe dir|git source|file source] [--json]
qs list templates [recipe file|recipe dir|git source|file source] [--json]
qs inspect template [recipe file|recipe dir|git source|file source] <template-id> [--json]
qs last [--json]
qs repo fetch <git-source>
qs repo list [--json]
qs repo clean [git-source|--all] [--dry-run]
qs ghx get <github-url> -o <path> [--json]
qs ghx cat <github-url>
qs ghx doctor [--json]
qs version
qs export-example <path>
qs serve
```

根命令 `qs` 只显示帮助。需要诊断加载过程时，使用全局 `--verbose`，加载细节会写入 stderr。

## 输入路径规则

`render`、`run`、`explain`、`list templates` 和 `inspect template` 共享 recipe 输入规则：

1. 传入文件时，读取该文件。
2. 传入目录时，读取目录下的 `recipe.yaml`。
3. 不传输入时，读取当前目录下的 `recipe.yaml`。
4. 输入以 `git+` 开头时，先下载 Git source 到 repo cache，再读取 repo 内 recipe。
5. 输入是 HTTP(S) URL 时，先下载到 file cache，再按本地 recipe 文件解析。

```sh
qs explain ./recipe.yaml
qs explain .
qs explain git+https://example.com/org/qs-repo.git@v1.0.0
qs explain https://example.com/recipes/server.yml
```

## 信息命令

解释 recipe：

```sh
qs explain ./recipe.yaml
qs explain ./recipe.yaml --json
```

`explain` 会严格校验 recipe 中选中的 template 和参数覆盖。template ID 缺失、repo 歧义、template 文件不存在或覆盖未知参数时会失败。输出中会显示 `ghx` 开关状态；`--json` 中对应字段是 `ghx_enabled`。

列出 template：

```sh
qs list templates ./recipe.yaml
qs list templates ./recipe.yaml --json
qs list templates ./recipe.yaml --platform ubuntu --shell bash
```

`--platform` 按 `metadata.platform` 字符串包含过滤，`--shell` 按 `metadata.shell` 精确过滤。

检查 template：

```sh
qs inspect template ./recipe.yaml repo-name/component/install.sh
qs inspect template ./recipe.yaml repo-name/component/install.sh --json
```

`list templates` 和 `inspect template` 面向发现和检查 repo 内容，不要求 recipe 当前选中的所有 template 或参数覆盖都有效。

## 生成脚本

```sh
qs render ./recipe.yaml -o ./quick-setup.sh
```

`render` 使用与 `explain` 相同的解析和校验逻辑。输出路径会转成绝对路径，生成脚本会设置为可执行。

## 执行生成内容

```sh
qs run ./recipe.yaml
qs run ./recipe.yaml --record-dir ./runs
qs run ./recipe.yaml --no-record
```

`run` 会生成脚本文件，再通过 `bash <script.sh>` 执行。Windows 下默认优先使用 Git for Windows 的 Git Bash；如需指定执行器，可设置 `QS_BASH`。

默认会保存运行记录。`--record-dir <dir>` 指定单次记录基础目录，`--no-record` 关闭记录并使用临时脚本执行。

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
qs ghx get https://raw.githubusercontent.com/owner/repo/main/file.sh -o file.sh
qs ghx cat https://raw.githubusercontent.com/owner/repo/main/file.sh
```

GHX 的自建转发、Cloudflare Worker、token header 和 provider 顺序由 GHX 配置控制，不写入 QS recipe。

## 最近运行记录

```sh
qs last
qs last --json
```

`last` 读取默认全局运行日志目录中的最近一次记录。`last --json` 输出紧凑摘要，包含状态、退出码、时间、输入、执行器、脚本路径和日志路径。

## repo cache 命令

只下载远程 Git repo，不渲染、不执行：

```sh
qs repo fetch git+https://example.com/org/qs-repo.git@v1.0.0
```

列出本地 Git repo cache：

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

`repo clean` 默认会删除匹配项。清理前建议先用 `--dry-run` 预览。

## 其他命令

输出版本：

```sh
qs version
```

导出内置示例仓库：

```sh
qs export-example ./demo
```

启动本地 HTTP demo server：

```sh
qs serve
```

`serve` 当前固定监听 `127.0.0.1:8000`。

## 安全建议

- 默认先 `explain`、`list templates`、`inspect template`，再 `render`。
- 审查生成脚本后，只有明确需要执行时才 `run`。
- 涉及 `sudo`、系统目录、服务重启、远程来源或网络下载时，先确认 template 元数据和脚本内容。
- Agent 需要解析命令结果时，优先使用信息命令的 `--json`。
- 诊断解析过程时用 `--verbose`，不要把 stderr 诊断信息当作 JSON 主体。
