# 远程来源与缓存

QS 支持远程 repo、远程 recipe 和远程 framework，但远程内容都会先缓存到本地，再按本地文件或 repo 解析。QS 不把普通远程 shell 文本当作脚本直接执行。

## 远程来源类型

当前远程输入先归一为两类资产来源：

- Git source：用于组件库 repo，也可用于 repo 内 recipe/framework 文件。
- HTTP(S) file source：用于 recipe 和 framework 单文件。

用户可以使用规范 `git+` 格式，也可以直接复制 GitHub 页面链接。普通 GitHub repo 根页面和根 tree 页面会被当作 repo；GitHub blob/raw recipe 文件页面会被当作 recipe。

## GitHub 与 GHX

以下 GitHub 输入会自动通过 QS 内置 GHX SDK 访问：

- GitHub repo URL 和根 tree URL。
- GitHub blob/raw recipe 或 framework 文件 URL。
- GitHub `git+` repo source。
- 生成脚本中常见 GitHub `curl` / `wget` 下载形态。

QS 使用 GHX embedded profile，配置读取：

```text
~/.qs/config/ghx.yaml
当前工作目录下的 .qs/ghx.yaml
当前工作目录下的 ghx.yaml
```

诊断当前 QS 能读取到的 provider：

```sh
qs ghx doctor
qs ghx doctor --json
```

生成脚本中的 GHX runtime shim 默认开启。它只接管 GitHub URL，非 GitHub URL 会回退到系统原始 `curl` / `wget`。如需关闭：

```yaml
qs:
  ghx: false
```

## Git source

规范格式：

```text
git+<git-url>.git
git+<git-url>.git@<ref>
git+<git-url>.git@<ref>//<recipe-path>
```

GitHub 页面链接：

```text
https://github.com/<owner>/<repo>
https://github.com/<owner>/<repo>/tree/<ref>
```

说明：

- `<ref>` 可以是 branch、tag 或 commit SHA。
- `<ref>` 为空时使用远程默认分支 HEAD。
- `<recipe-path>` 为空时，`render` 和 `run` 使用 repo 内的 `recipe.yaml`，`inspect` 按 repo 扫描。
- `<recipe-path>` 必须是 repo 内相对路径，不能使用绝对路径或 `..` 越界。
- 规范 Git URL 必须带 `.git`，用于避免 SSH 地址、Windows 路径和 recipe 路径分隔歧义。
- GitHub tree 子目录当前不作为 repo root 支持。

示例：

```sh
qs inspect https://github.com/yuanboshe/qs-repo/tree/devel --json
qs render git+https://example.com/org/qs-recipes.git@v1.0.0//server/recipe.yaml -o ./quick-setup.sh
```

## HTTP(S) file source

格式：

```text
https://example.com/path/to/recipe.yml
https://example.com/path/to/
https://github.com/<owner>/<repo>/blob/<ref>/<recipe-path>
https://raw.githubusercontent.com/<owner>/<repo>/<ref>/<recipe-path>
```

说明：

- URL 明确指定文件名时，按该文件读取。
- URL 路径为空或以 `/` 结尾时，默认拼接 `recipe.yaml`。
- 文件名不要求必须是 `recipe.yaml`。
- 下载后会把缓存文件作为本地文件继续解析。
- GitHub repo 内文件会优先复用已缓存的同 repo/ref snapshot。
- GitHub repo 内 recipe 未命中 repo snapshot 时，会先下载单文件；如果 recipe 省略 `qs.repos`，或包含相对 `repos[].path`、`repos[].path: .`、相对 `qs.framework`，则继续下载完整 repo snapshot 并使用 snapshot 内 recipe。

示例：

```sh
qs inspect https://github.com/yuanboshe/qs-repo/blob/example-repo/recipe.yaml --json
qs render https://example.com/recipes/ -o ./quick-setup.sh
```

## 缓存目录

默认 QS home 位于 `~/.qs`。主要目录：

```text
~/.qs/repos   组件库完整源码快照，不保留 .git
~/.qs/files   recipe/framework 单文件缓存
~/.qs/ghx     GHX 字节缓存
~/.qs/runs    run 运行记录
~/.qs/config  配置文件
```

`QS_HOME` 可以整体改变 QS home。repo、file 和 run 目录也分别支持 `QS_REPOS_DIR`、`QS_FILES_DIR` 和 `QS_RUNS_DIR` 覆盖。

## Repo cache

远程 repo cache 条目是可直接阅读的组件仓库快照：

```text
~/.qs/repos/<repo-id>@<commit-short>/
  .qs-cache.json
  <repo files>
```

示例：

```text
~/.qs/repos/github.com--yuanboshe--qs-repo@b329a039/
```

同一 GitHub repo 的直接 URL 和 `git+...git` 在同 commit 下会归一到同一 repo cache。repo cache 不保留 `.git` 目录和历史记录。

## File cache

GitHub repo 内文件按 repo id 和 ref/commit 建目录，并在目录内保留 repo 相对路径：

```text
~/.qs/files/github.com--owner--repo@<ref-or-commit>/
  <repo-relative-path>
```

非 GitHub file source 没有 repo 身份，按 URL 和内容 hash 生成文件缓存条目：

```text
~/.qs/files/<readable-file-key>~<url-hash-short>@<content-hash-short>/
  <downloaded file>
```

file cache 不写额外 `.qs-file.json` 元数据。GitHub repo 内文件如果已存在同 repo/ref 的 repo snapshot，则直接复用 repo 内文件，不再在 `files` 中保存重复副本；如果 GitHub repo 内 recipe 后续切换为完整 repo snapshot，也会删除本次刚下载的重复单文件缓存。

## 清理缓存

```sh
qs clean --dry-run
qs clean
```

`qs clean` 删除 `repos`、`files` 和 `ghx` 三类资产缓存，不删除 `runs` 运行记录和 `config` 配置。没有明确清理意图时，先使用 `--dry-run`。

## 使用建议

- 普通 GitHub 输入优先直接复制 GitHub repo/tree/blob/raw URL。
- 需要非 GitHub Git、SSH/private repo、显式 ref 或 repo 内 recipe 路径时，再使用 `git+`。
- 远程 Git source 优先使用 tag 或 commit SHA。
- 使用默认分支或浮动分支时，生成结果可能随远端变化。
- 远程来源参与执行前，先 `inspect`，再 `render` 审查脚本。
