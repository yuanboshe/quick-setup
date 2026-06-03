# 核心概念

QS 的心智模型是：

```text
repo 提供组件库
component 负责分类
template 是可复用功能脚本
recipe 选择 template 并设置参数
framework 决定最终脚本外层结构
```

这套模型的目标是把可复用 shell 操作拆清楚：template 保持普通脚本可读，recipe 只描述本次要组合什么，framework 只负责最终脚本的组织方式。

## recipe

`recipe` 是 QS 的入口配置资产。默认入口文件名是 `recipe.yaml`。

```yaml
qs:
  repos:
    - path: .
      name: repo-name
  framework: framework.sh
  templates:
    - repo-name/component1_simple/hello.sh
    - component2_config_file/showtime.sh
    - component3_multi_files/hello.sh
    - bye.sh

repo-name/component3_multi_files/hello.sh:
  name: 用户参数
```

核心字段：

- `qs.repos[].path`：组件库路径，可以是本地路径或 `git+` Git source。
- `qs.repos[].name`：repo 逻辑名称，可省略；QS 会从路径推断。
- `qs.framework`：framework 文件，可省略；省略时使用内置默认 framework。
- `qs.templates`：本次选择的 template 列表，是必填字段。

recipe 中的参数覆盖只覆盖已声明参数。参数必须来自 template 路径上的 `config.yaml.args`，或 template 文件中的 `# @arg` 标记。

## repo

`repo` 是组件库，也是 Git 管理、发布、复用和信任边界。一个最小 repo 可以只包含 component 和 template：

```text
qs-repo/
  docker/
    install_docker.sh
  golang/
    install_go.sh
```

repo 根目录可以放示例 `recipe.yaml`、`framework.sh` 和默认上下文 `config.yaml`，但它们不是每个组件库的必需文件。

## component

`component` 是 repo 里的分类目录。分类方式由维护者决定，可以按技术栈、系统能力、安装目标或场景划分。

```text
qs-repo/
  docker/
  nodejs/
  server_init/
```

component 可以继续包含多级目录。template ID 会保留这些目录层级。

## template

`template` 是具体功能脚本，通常是 `.sh` 文件。它应该表达一个清晰功能意图，例如安装 Docker、配置 Go、修改源、验证环境或输出诊断信息。

```sh
#!/bin/bash

# @description 打印问候信息
# @arg 名称
NAME="默认值"

main() {
  echo "hello [${NAME}]"
}

main
```

QS 通过 shell 注释里的 `# @` 标记读取说明、参数和元数据。template 本身仍然是普通 shell 脚本，应该能被人类直接审查。

## template config

`config.yaml` 固定表示 repo 或 template 目录中的默认上下文文件。它包含 `args` 和 `metadata` 两个块。

```yaml
args:
  version: latest
  mirror: auto

metadata:
  platform:
    - linux/ubuntu>=20.04
  shell: bash
  effects:
    - package-install
```

QS 会从 repo 根目录开始，沿 template 路径逐级读取 `config.yaml`。越靠近 template 的目录覆盖越上层目录。

## framework

`framework` 是最终脚本外层模板，使用 Go `text/template` 渲染。它接收已渲染的 template 列表，把它们组织成最终 shell 脚本。

::: v-pre
```sh
#!/bin/bash

{{range $template := .templates}}
echo "-------------------- template {{$template.templateId}} --------------------"
{{$template.content}}
{{end}}
```
:::

framework 可以统一添加 header、错误处理、分隔输出或执行包装，但不应承载具体安装逻辑。

## 生成计划

`qs explain` 会输出生成计划，包括实际 recipe 路径、repo、framework、template 和参数最终值。`render` 和 `run` 使用同一套解析结果，因此推荐先 `explain` 再 `render`。

## 运行记录

`qs run` 默认保存运行记录。记录中包含：

```text
plan.json
script.sh
stdout.log
stderr.log
result.json
```

执行失败后，先用 `qs last` 或 `qs last --json` 找到最近记录，再读取脚本和日志定位问题。

## 远程来源

QS 当前支持两类远程输入：

- `git+` Git source：可用于 recipe、repo 和 framework。
- HTTP(S) file source：可用于 recipe 和 framework 文件。

远程内容会先缓存到本地，再按本地文件或 repo 解析。QS 不把普通远程 shell 文本当作脚本直接执行。

## 推荐协作路径

```text
explain / list templates / inspect template
  -> render
  -> 审查生成脚本
  -> run
  -> last
  -> 根据记录修改 recipe 或 template
```

更多细节见 [Agent 协作流程](../manual/agent-workflow.md)。
