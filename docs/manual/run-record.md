# 运行记录

`qs run` 默认保存运行记录，用于在执行后追踪生成计划、脚本内容、执行器、stdout、stderr 和结果摘要。

## run 的执行方式

`run` 会先生成脚本文件，再通过：

```sh
bash <script.sh>
```

执行生成内容。

Windows 下默认优先使用 Git for Windows 的 Git Bash。需要指定自定义 bash 时，可以设置 `QS_BASH`。执行生成脚本时，QS 会设置 `QS_BIN` 指向当前 `qs` 可执行文件，供 GHX runtime shim 调用。

## 默认记录位置

默认全局运行日志目录：

```text
~/.qs/runs
```

环境变量：

- `QS_HOME`：默认运行日志目录改为 `$QS_HOME/runs`。
- `QS_RUNS_DIR`：直接指定默认运行日志目录，优先级高于 `QS_HOME`。

每次运行写入一个 `<run-id>` 目录。

## 记录文件

运行记录包含：

```text
plan.json
script.sh
stdout.log
stderr.log
result.json
```

文件说明：

- `plan.json`：解析后的生成计划，包含 `ghx_enabled` 开关状态。
- `script.sh`：实际执行的生成脚本。
- `stdout.log`：执行过程 stdout。
- `stderr.log`：执行过程 stderr。
- `result.json`：状态、退出码、时间、输入、执行器和日志路径摘要。

## 指定记录目录

```sh
qs run ./recipe.yaml --record-dir ./runs
```

实际记录会写入 `<record-dir>/<run-id>/`。

## 关闭记录

```sh
qs run ./recipe.yaml --no-record
```

`--no-record` 会关闭运行记录。

## 查看最近记录

```sh
qs last
qs last --json
```

`last` 从默认全局运行日志目录中读取最近一次 `result.json`。如果你使用 `--record-dir` 指定了其他目录，`last` 不会自动扫描该目录。

`last --json` 只输出紧凑摘要，不内嵌完整脚本或 stdout/stderr 日志。

## 排错流程

执行失败后推荐顺序：

1. 运行 `qs last --json` 找到最近记录。
2. 打开 `result.json` 查看退出码和执行器。
3. 打开 `script.sh` 确认实际执行内容。
4. 查看 `stderr.log` 和 `stdout.log`。
5. 根据问题修改 recipe、template 或运行环境。

如果问题与解析有关，回到 `qs explain` 或 `qs inspect template` 检查参数和 template 来源。
