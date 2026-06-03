# 远程来源与缓存

QS 支持远程 recipe、远程 repo 和远程 framework，但远程内容都会先缓存到本地，再按本地文件或 repo 解析。

## 远程来源类型

当前支持两类远程输入：

- Git source：用于 recipe、repo 和 framework。
- HTTP(S) file source：用于 recipe 和 framework 文件。

HTTP(S) file source 是可读取文件资产，不表示直接执行远程 shell 文本。QS 不支持 `curl | bash` 式远程执行。

## Git source

格式：

```text
git+<git-url>.git
git+<git-url>.git@<ref>
git+<git-url>.git@<ref>//<recipe-path>
```

说明：

- `<ref>` 可以是 branch、tag 或 commit SHA。
- `<ref>` 为空时使用远程默认分支 HEAD。
- `<recipe-path>` 为空时使用 repo 内的 `recipe.yaml`。
- `<recipe-path>` 必须是 repo 内相对路径，不能使用绝对路径或 `..` 越界。
- Git URL 必须带 `.git`，用于避免地址和路径分隔歧义。

示例：

```sh
qs explain git+https://example.com/org/qs-recipes.git@v1.0.0//server/recipe.yaml
qs render git+https://example.com/org/qs-recipes.git@v1.0.0 -o ./quick-setup.sh
```

## HTTP(S) file source

格式：

```text
https://example.com/path/to/recipe.yml
https://example.com/path/to/
```

说明：

- URL 明确指定文件名时，按该文件读取。
- URL 路径为空或以 `/` 结尾时，默认拼接 `recipe.yaml`。
- 文件名不要求必须是 `recipe.yaml`。
- 下载后会把缓存文件作为本地文件继续解析。

示例：

```sh
qs explain https://example.com/recipes/server.yaml
qs render https://example.com/recipes/ -o ./quick-setup.sh
```

## Git repo cache

远程 Git repo 默认缓存到：

```text
~/.qs/repos
```

可以通过环境变量覆盖：

- `QS_HOME`：repo cache 使用 `$QS_HOME/repos`。
- `QS_REPOS_DIR`：直接指定 repo cache 目录，优先级高于 `QS_HOME`。

cache 条目是可直接阅读的组件仓库快照：

```text
~/.qs/repos/<readable-repo-key>~<url-hash-short>@<commit-short>/
  .qs-cache.json
  <repo files>
```

如果同一远程 repo 和 commit 的缓存已存在，QS 会复用缓存。

## File cache

远程文件默认缓存到：

```text
~/.qs/files
```

可以通过环境变量覆盖：

- `QS_HOME`：file cache 使用 `$QS_HOME/files`。
- `QS_FILES_DIR`：直接指定 file cache 目录，优先级高于 `QS_HOME`。

cache 条目包含下载文件和 `.qs-file.json` 元数据：

```text
~/.qs/files/<readable-file-key>~<url-hash-short>@<content-hash-short>/
  .qs-file.json
  <downloaded file>
```

如果同 URL、同内容的缓存已存在，QS 会复用本地文件和元数据。

## repo cache 命令

提前下载 Git repo：

```sh
qs repo fetch git+https://example.com/org/qs-repo.git@v1.0.0
```

列出本地 Git repo cache：

```sh
qs repo list
qs repo list --json
```

清理指定或全部 Git repo cache：

```sh
qs repo clean git+https://example.com/org/qs-repo.git@v1.0.0 --dry-run
qs repo clean git+https://example.com/org/qs-repo.git@v1.0.0
qs repo clean --all --dry-run
qs repo clean --all
```

`repo clean` 默认会删除匹配 cache。没有明确清理意图时，先使用 `--dry-run`。

## 使用建议

- 远程 Git source 优先使用 tag 或 commit SHA。
- 使用默认分支或浮动分支时，生成结果可能随远端变化。
- 远程来源参与执行前，先 `explain`、`list templates` 或 `inspect template`，再 `render` 审查脚本。
- 不要把未知远程 shell 文本当作可直接执行内容。
