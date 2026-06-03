---
name: qs-repo
description: Use when creating, modifying, reviewing, or documenting quick-setup component repositories, components, shell templates, template config.yaml files, recipe files, frameworks, template IDs, argument markers, or repo publishing/versioning guidance.
---

# QS Repo

开发 quick-setup（QS）组件库时，把 repo 视为可复用 shell 安装能力的发布单位。目标是让人类能审查脚本，让 Agent 能稳定发现、组合、解释和执行 template。

## 核心模型

```text
repo 提供组件库
component 负责分类
template 是可复用功能脚本
recipe 像配方一样选择 template 并设置参数
framework 决定最终脚本外层结构
```

repo 是 Git 管理、发布和复用单位。component 是 repo 下的分类。template 是普通 shell 脚本，不应退化成复杂 DSL。

## Repo 结构

最小组件库：

```text
qs-repo/
  docker/
    install_docker.sh
    install_compose.sh
  golang/
    install_go.sh
```

带示例 recipe 和 framework 的组件库：

```text
qs-repo/
  recipe.yaml
  framework.sh
  docker/
    config.yaml
    install_docker.sh
  golang/
    install_go.sh
```

repo 根目录的 `recipe.yaml` 和 `framework.sh` 通常用于示例、测试或快速运行，不是组件库必需文件。repo 根目录的 `config.yaml` 如果存在，表示全 repo template 默认上下文。

## Template 写法

template 应表达一个清晰功能意图，例如安装 Docker、配置 Go、检查网络、初始化用户或输出诊断信息。避免把多个无关安装流程塞进同一个 template。

推荐结构：

```sh
#!/bin/bash

# @description 安装或升级 Go 到指定版本

# @arg Go 版本，空值表示 latest
VERSION="latest"

main() {
  echo "install go ${VERSION}"
}

main
```

写 template 时遵循：

- 保持普通 shell 可读，可被人类直接审查。
- 用函数组织主体逻辑，避免顶层堆叠过长命令。
- template 负责具体功能，framework 负责最终脚本组织。
- 涉及 `sudo`、系统目录、服务重启、远程下载或破坏性修改时，在 `# @description` 或脚本输出中写清楚风险。
- 涉及特定系统、解释器、依赖、网络访问或系统副作用时，用 template 元数据标记写清楚适配边界。
- 参数默认值放在 template 中，场景差异通过配置覆盖。

## 复用沉淀规则

Agent 组织复杂流程时，如果流程具备复用价值，应优先沉淀为 QS 组件资产，而不是只执行一次性命令。以下情况通常值得沉淀：

- 包含多步骤安装、配置、验证或故障处理。
- 涉及 `sudo`、软件源、系统目录、服务重启、用户组权限或远程下载。
- 未来可能在其他服务器、虚拟机或同类项目中重复执行。
- 执行中暴露了网络、系统版本、权限或工具链兼容问题，需要把修复经验保留下来。

沉淀方式：

- 新增或修改 component 下的 template，把可复用步骤写成普通 shell。
- 用 `# @description` 和元数据标记记录功能意图、适配边界和主要风险。
- 用 `# @arg` 暴露场景差异参数，不把环境差异硬编码进脚本主体。
- 用 repo 或 template 目录中的 `config.yaml` 放共享 `args` 和 `metadata` 默认值，用 recipe 组合具体流程。
- 不在 component 内新增 README 作为 template 事实源；组件能力信息应进入 template 注释、template config 或根 README 导航。

## QS 标记

QS 标记写在 shell 注释中，由 `# @` 开头。

当前常用标记：

- `# @description ...`：template 描述。
- `# @arg ...`：声明后续变量赋值可被配置覆盖。
- `# @platform ...`：声明适配平台或系统版本，多个值用空格或逗号分隔。
- `# @shell ...`：声明脚本解释器，例如 `bash`。
- `# @requires ...`：声明执行依赖，多个值用空格或逗号分隔。
- `# @effects ...`：声明主要副作用，多个值用空格或逗号分隔。
- `# @network ...`：声明主要网络访问目标，多个值用空格或逗号分隔。

元数据示例：

```sh
# @description 通过 Docker apt 仓库安装 Docker Engine
# @platform linux/ubuntu>=22.04 linux/debian>=12
# @shell bash
# @requires sudo apt-get curl systemd
# @effects apt-source package-install service-restart user-group
# @network download.docker.com mirrors.aliyun.com
```

`qs explain --json`、`qs list templates --json` 和 `qs inspect template --json` 会输出这些元数据，Agent 应用它们判断目标系统、解释器、依赖、权限和网络风险。

`# @arg` 绑定它后面的第一个非注释变量赋值：

```sh
# @arg 下载镜像源
MIRROR="https://example.com/mirror"
```

解析规则：

- 参数名来自变量名，并转成小写。
- 配置变量名使用小写，可以匹配脚本中任意大小写形式的变量名。
- 原始赋值使用单引号、双引号或无引号时，渲染后保留原引号形式。
- `# @arg` 和变量赋值之间可以有空行，但不要插入其他命令。
- 需要使用 `config.yaml.args` 作为默认值时，把变量写成同名 Go template 占位符，例如 `NAME="{{.name}}"`；这会声明参数和说明，但不会用 template 默认值覆盖 config。
- 需要 template 明确默认值为空字符串时，写 `NAME=""`；这会覆盖 config 中的同名默认值。

常见写法：

```sh
# @arg 名称，默认来自 config 或 recipe，缺省为空
NAME="{{.name}}"

# @arg 名称，template 默认值明确为空
NAME=""

# @arg 名称，template 默认值明确为 default
NAME="default"
```

多行说明可以用反斜杠连接：

```sh
# @description 第一行 \
# 第二行
```

## Template Config

`config.yaml` 固定表示 template 默认上下文文件，可以放在 repo 根目录，也可以放在 template 路径上的任一目录。它不是 recipe 默认文件名。

目录级默认值：

```yaml
args:
  version: latest
  mirror: auto

metadata:
  platform:
    - linux/ubuntu>=20.04
    - linux/debian>=11
  shell: bash
  effects:
    - package-install
```

多级目录默认值按路径逐级覆盖：repo 根目录 `config.yaml` 先进入默认上下文，子目录 `config.yaml` 覆盖父目录。然后 template 中的 `# @arg` 默认值覆盖这些目录 `args` 默认值，recipe 覆盖所有参数默认值。template 注释元数据覆盖目录 `metadata` 默认值。

规则：

- 参数默认值必须写在 `args` 中，不要写成顶层字段。
- 元数据默认值必须写在 `metadata` 中。
- `metadata.description` 会成为 template 说明；`# @description` 会覆盖它。
- `metadata.platform`、`metadata.requires`、`metadata.effects` 和 `metadata.network` 可写 YAML list，也可写空白或逗号分隔字符串。
- 列表型 metadata 字段按层级整体覆盖，不自动追加；空列表可以清空父级默认值。

`config.yaml` 适合放一组 template 共享的环境默认值；template 自己强约束的默认值应放在 `# @arg` 后面的变量赋值或 template 元数据注释中。

## Recipe

`recipe` 选择 repo、framework 和 templates。默认文件名通常是 `recipe.yaml`，但 source 明确指定文件时不要求必须使用这个文件名。Recipe 可以来自本地文件、本地目录默认文件、Git repo 内文件或 HTTP(S) file source。GitHub 远程来源由 QS 内置 GHX SDK 访问，不要求用户单独安装 `ghx` 二进制。

`qs.ghx` 默认开启。开启时，最终生成脚本会注入 GHX runtime shim，让 GitHub URL 的常见 `curl` / `wget` 下载形态通过 QS 内置 GHX SDK 访问。组件 template 可以继续保持普通 `curl` / `wget` 写法；如果某个 recipe 需要完全保留原始网络行为，可以关闭：

```yaml
qs:
  ghx: false
```

GHX provider、Worker、自建转发服务和 token header 属于本机或项目级 GHX 配置，不写入 recipe。

编写 `recipe` 时，区分核心必填参数和可推理参数。核心必填参数必须写清楚；可推理参数能省略时优先省略，让 recipe 保持简单。

```yaml
qs:
  repos:
    - path: .
      name: repo
  framework: framework.sh
  templates:
    - repo/golang/install_go.sh
    - docker/install_docker.sh
    - install_compose.sh

repo/golang/install_go.sh:
  version: 1.23.0
```

`qs.repos[].path` 可以是本地绝对路径、本地相对路径或远程 Git source。组件库是 repo 资产，不要把 HTTP(S) file source 写入 `repos[].path`。

```yaml
qs:
  repos:
    - path: git+https://example.com/org/qs-repo.git@v1.0.0
      name: base
```

GitHub Git source 会通过 GHX 获取 archive snapshot；非 GitHub Git source 仍依赖本机 `git`。远程 repo 发布时仍建议 pin 到 tag 或 commit SHA，避免 floating branch 带来的不可复现。

字段分层：

- `qs.templates` 是核心必填参数，决定 `recipe` 组合哪些 template。
- `qs.repos[].path` 是核心必填参数，决定组件库来源。
- `qs.repos[].name` 是可推理参数；多个 repo 可能重名时再显式填写。
- `qs.framework` 是可推理参数；省略时使用默认 framework。
- `qs.ghx` 是可推理参数；省略时启用 GHX runtime shim，显式 `false` 时关闭。

省略 `name` 时，QS 会从 repo path 推断名称。如果多个 repo 可能重名，显式填写 `name`。

`qs.templates` 支持三种写法：

```text
repo/template-dir/template
component/template
template
```

三段及更多段的完整写法最清晰，适合跨 repo 或长期维护；中间多段表示多级目录。两段和一段写法依赖前文上下文，只在相邻模板语义清楚时使用。

参数覆盖顺序从低到高：

1. repo 根目录 `config.yaml.args`。
2. template 路径上每一级目录的 `config.yaml.args`，子目录覆盖父目录。
3. template 中 `# @arg` 默认值。
4. `recipe` 中的 `repo`。
5. `recipe` 中的 `repo/<template-dir>`，多级目录逐级覆盖。
6. `recipe` 中的 `repo/<template-dir>/<template-name>`。

recipe 只能覆盖对应 template 已声明的参数。可用参数来自该 template 路径上的 `config.yaml.args` 和 template 文件中的 `# @arg` 声明；如果 recipe 覆盖了未声明参数，`explain`、`render` 和 `run` 会失败。需要暴露新参数时，先在 `config.yaml.args` 写默认值，或在 template 中加 `# @arg` 标记。

metadata 覆盖顺序从低到高：

1. repo 根目录 `config.yaml.metadata`。
2. template 路径上每一级目录的 `config.yaml.metadata`，子目录覆盖父目录。
3. template 中的 `# @description`、`# @platform`、`# @shell`、`# @requires`、`# @effects` 和 `# @network`。

recipe 不覆盖 metadata；metadata 描述 template 自身能力边界。

## Framework

framework 是最终脚本外层模板，使用 Go `text/template` 渲染。

可用数据：

- `.templates`：已渲染 template 列表。
- 每项包含 `templateId` 和 `content`。

最小 framework：

```sh
#!/bin/bash

{{range $template := .templates}}
echo "-------------------- template {{$template.templateId}} --------------------"
{{$template.content}}
{{end}}
```

framework 可以统一加 header、错误处理、分隔输出或执行包装，但不应承载具体业务安装逻辑。template 不应依赖某个 framework 的私有约定。

`qs.framework` 可以是本地文件、repo 内路径、Git source 或 HTTP(S) file source。省略时使用默认 framework。本地路径找不到时会回退默认 framework；显式远程 source 下载失败时应视为错误。GitHub framework source 同样通过 GHX SDK 访问。

## 发布和维护

- 远程 repo 发布时，建议提供 tag 或 commit SHA 供 `recipe` pin 版本。
- 不要把 template 写成单条不可审查的长命令；优先沉淀为清晰脚本。
- 不要让 `recipe` 变成复杂工作流语言；它只负责选择 template 和覆盖参数。
- 修改 template ID、参数名或默认行为时，考虑已有 `recipe` 的兼容性。
- 删除或重命名 template 前，优先提供迁移说明或兼容路径。

## 检查清单

- repo、component、template 的职责是否清楚。
- template 是否能被人类直接审查。
- `# @description` 是否说明功能意图和主要风险。
- 元数据是否声明了目标平台、解释器、依赖、副作用和网络访问。
- `# @arg` 是否只暴露真正需要配置的参数。
- `recipe` 是否使用清晰的 template ID。
- 远程 repo 是否建议 pin 到稳定版本。
- framework 是否只负责脚本外层结构，没有混入具体业务功能。
