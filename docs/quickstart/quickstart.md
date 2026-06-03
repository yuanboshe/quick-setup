# 快速开始

本页用内置示例仓库演示 QS 的推荐使用路径：先理解 recipe 和 template，再生成脚本审查，最后才按需执行。

## 准备命令

安装或下载 `qs` 二进制后，先确认命令可用。

```sh
qs version
qs --help
```

根命令 `qs` 只显示帮助。生成、解释、执行和缓存管理都通过明确子命令完成。

## 导出示例仓库

QS 内置了一个 `example-repo`，可用于学习 repo、template、recipe 和 framework 的关系。

```sh
qs export-example ./_tmp
```

导出后可以看到类似结构：

```text
example-repo/
  recipe.yaml
  framework.sh
  config.yaml
  component1_simple/
    hello.sh
    bye.sh
  component2_config_file/
    showtime.sh
  component3_multi_files/
    config.yaml
    hello.sh
    bye.sh
```

`recipe.yaml` 是入口配置资产。`config.yaml` 是 repo 或 template 目录的默认上下文文件，不是入口文件名。

## 理解生成计划

先解释 recipe，确认实际使用的 repo、framework、template 和参数。

```sh
qs explain ./_tmp/example-repo/recipe.yaml
qs explain ./_tmp/example-repo/recipe.yaml --json
```

如果你传入目录，QS 会读取该目录下的 `recipe.yaml`。

```sh
qs explain ./_tmp/example-repo
```

不传输入时，QS 会读取当前目录下的 `recipe.yaml`。

## 发现和检查 template

列出 recipe 声明 repo 中的可用 template：

```sh
qs list templates ./_tmp/example-repo/recipe.yaml
qs list templates ./_tmp/example-repo/recipe.yaml --json
```

检查单个 template 的说明、参数、元数据和来源路径：

```sh
qs inspect template ./_tmp/example-repo/recipe.yaml repo-name/component1_simple/hello.sh
```

需要按元数据过滤时，可以使用：

```sh
qs list templates ./_tmp/example-repo/recipe.yaml --platform ubuntu --shell bash
```

## 生成脚本并审查

生成脚本到指定路径：

```sh
qs render ./_tmp/example-repo/recipe.yaml -o ./_tmp/quick-setup.sh
sed -n '1,200p' ./_tmp/quick-setup.sh
```

`render` 会写入可执行脚本。审查时重点看 template 顺序、参数最终值、是否涉及安装软件、系统目录、服务重启或网络下载。

## 按需执行

只有在你确认需要执行生成内容时，再使用 `run`。

```sh
qs run ./_tmp/example-repo/recipe.yaml
qs last
```

`run` 会先生成脚本文件，再通过 `bash <script.sh>` 执行。默认会保存运行记录，包含解析计划、生成脚本、stdout、stderr 和结果摘要。

## 下一步

- 想系统了解概念：阅读 [核心概念](concept.md)。
- 想查命令细节：阅读 [CLI 命令手册](../manual/cli.md)。
- 想编写入口配置：阅读 [recipe 手册](../manual/recipe.md)。
- 想维护组件库：阅读 [repo 与 component 手册](../manual/repo-component.md)。
