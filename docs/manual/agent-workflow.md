# Agent 协作流程

QS 面向 Agent 的默认协作路径是先理解、再生成、再审查、最后按需执行。不要把 QS 当成绕过审查的远程 shell 执行入口。

## 推荐流程

```text
explain / list templates / inspect template
  -> render
  -> 人类或 Agent 审查生成脚本
  -> run
  -> last
  -> 修改 recipe 或 template
```

## 第一步：理解输入

先解释 recipe：

```sh
qs explain ./recipe.yaml
qs explain ./recipe.yaml --json
```

发现可用 template：

```sh
qs list templates ./recipe.yaml
qs list templates ./recipe.yaml --json
```

检查单个 template：

```sh
qs inspect template ./recipe.yaml repo-name/component/install.sh
qs inspect template ./recipe.yaml repo-name/component/install.sh --json
```

Agent 需要结构化解析时，优先使用 `--json`。人类阅读时，使用默认文本输出。

## 第二步：审查风险

执行前重点检查：

- recipe 使用了哪些 repo，是否来自远程 Git source。
- framework 是否来自远程来源。
- template 的 `metadata.platform` 是否符合目标系统。
- `metadata.shell` 是否是当前可用解释器。
- `metadata.requires` 是否涉及缺失命令或高权限依赖。
- `metadata.effects` 是否涉及软件安装、系统文件、服务重启或用户组修改。
- `metadata.network` 是否访问可信网络位置。
- recipe 覆盖的参数是否符合预期。

当前 QS 只输出这些元数据，不自动完成环境适配校验。审查结论需要人类或 Agent 自行判断。

## 第三步：生成脚本

```sh
qs render ./recipe.yaml -o ./quick-setup.sh
```

审查生成脚本时，看实际 shell 内容，不只看 recipe。远程来源、`sudo`、系统目录写入、服务重启、包管理器操作和下载命令都应额外确认。

## 第四步：明确需要时执行

只有用户明确要求，或任务目标必须执行时，才使用：

```sh
qs run ./recipe.yaml
```

如果需要保存到指定位置：

```sh
qs run ./recipe.yaml --record-dir ./runs
```

除非有明确理由，不建议跳过运行记录。

## 第五步：读取记录

```sh
qs last
qs last --json
```

根据 `last` 输出找到：

- 实际执行器。
- 实际脚本路径。
- stdout 日志路径。
- stderr 日志路径。
- 退出码和状态。

失败后不要只根据终端最后几行判断；优先读取运行记录中的完整脚本和日志。

## 远程来源协作

使用远程来源时：

- Git source 优先使用 tag 或 commit SHA。
- 使用默认分支或浮动分支时，说明结果可能随远端变化。
- 远程 repo 可以先用 `qs repo fetch` 下载，再用 `qs repo list` 查看 cache。
- 清理 cache 前先用 `qs repo clean --dry-run`。
- HTTP(S) file source 只作为 recipe 或 framework 文件输入，不是远程脚本执行入口。

## 沉淀经验

如果一次操作具备复用价值，优先把经验沉淀回 QS 资产：

- 可复用步骤写成 template。
- 共享参数和元数据写入目录 `config.yaml`。
- 具体场景组合写入 recipe。
- 脚本外层组织写入 framework。

不要把长期可复用的系统操作只保留为一次性终端命令。
