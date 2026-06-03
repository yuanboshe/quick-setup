# 快速开始

本页只做一件事：用内置示例仓库把 QS 的最小闭环跑起来。

## 1. 安装并确认命令

Linux 用户可以直接安装：

```sh
curl -fsSL https://qs.pz1.top/install.sh | bash
qs version
```

其他平台先从 [下载页](../download/) 获取二进制，再确认命令可用：

```sh
qs version
qs --help
```

根命令 `qs` 只显示帮助；实际动作都使用明确子命令。

## 2. 导出示例仓库

```sh
qs export-example ./demo
```

导出后得到：

```text
demo/example-repo/
  recipe.yaml
  framework.sh
  component1_simple/
  component2_config_file/
  component3_multi_files/
```

`recipe.yaml` 是入口配置。`component*/` 目录里是可复用的 shell template。

## 3. 先解释 recipe

```sh
qs explain ./demo/example-repo
```

传入目录时，QS 会自动读取目录下的 `recipe.yaml`。`explain` 用来确认实际会使用哪些 repo、framework、template 和参数。

需要给 Agent 或脚本解析时使用 JSON：

```sh
qs explain ./demo/example-repo --json
```

## 4. 生成脚本

```sh
qs render ./demo/example-repo -o ./demo/quick-setup.sh
```

审查脚本：

```sh
sed -n '1,200p' ./demo/quick-setup.sh
```

生成脚本默认包含 GHX runtime shim。常见 GitHub `curl` / `wget` 下载会通过 QS 内置 GHX SDK 访问；非 GitHub URL 保持原命令行为。

## 5. 确认后执行

只有确认脚本内容符合预期时，再运行：

```sh
qs run ./demo/example-repo
qs last
```

`run` 会生成脚本文件并通过 `bash <script.sh>` 执行。默认保存运行记录，`last` 会显示最近一次结果、脚本路径和日志路径。

## 常用下一步

发现可用 template：

```sh
qs list templates ./demo/example-repo
```

检查单个 template：

```sh
qs inspect template ./demo/example-repo repo-name/component1_simple/hello.sh
```

诊断 GHX provider 配置：

```sh
qs ghx doctor
```

继续阅读：

- [核心概念](concept.md)
- [CLI 命令手册](../manual/cli.md)
- [recipe 手册](../manual/recipe.md)
