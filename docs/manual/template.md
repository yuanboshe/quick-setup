# template 手册

`template` 是 QS 的可复用功能脚本，通常是 `.sh` 文件。它应该保持普通 shell 可读，并通过轻量注释标记暴露说明、参数和元数据。

## 推荐结构

```sh
#!/bin/bash

# @description 安装或升级 Go 到指定版本
# @platform linux/ubuntu>=20.04 linux/debian>=11
# @shell bash
# @requires sudo curl tar
# @effects package-install system-file:/usr/local/go
# @network go.dev dl.google.com

# @arg Go 版本
VERSION="latest"

main() {
  echo "install go ${VERSION}"
}

main
```

建议每个 template 只表达一个清晰功能意图，例如安装软件、修改配置、验证环境或输出诊断信息。

## QS 标记

QS 标记写在 shell 注释里，由 `# @` 开头。

当前支持：

- `# @description ...`：template 描述。
- `# @arg ...`：声明后续变量赋值可被配置覆盖。
- `# @platform ...`：声明适配平台或系统版本。
- `# @shell ...`：声明脚本解释器。
- `# @requires ...`：声明执行依赖。
- `# @effects ...`：声明主要副作用。
- `# @network ...`：声明主要网络访问目标。

多个值可以用空格或逗号分隔。

```sh
# @platform linux/ubuntu>=22.04,linux/debian>=12
# @requires sudo apt-get curl systemd
# @effects apt-source package-install service-restart
# @network download.docker.com mirrors.aliyun.com
```

这些元数据会出现在 `explain --json`、`list templates --json` 和 `inspect template --json` 中，用于执行前审查。当前元数据不改变脚本生成内容，也不自动阻止执行。

## 参数声明

`# @arg` 绑定它后面的第一个非注释变量赋值：

```sh
# @arg 下载镜像源
MIRROR="https://example.com/mirror"
```

解析后：

- 参数名来自变量名，并转成小写。
- 配置中的参数名必须使用小写。
- 配置参数可以匹配脚本中任意大小写形式的变量名。
- 原始赋值使用单引号、双引号或无引号时，渲染后保留同类写法。
- `# @arg` 和变量赋值之间可以有空行。

## 默认值写法

使用 template 自身默认值：

```sh
# @arg 名称
NAME="default"
```

使用 `config.yaml.args` 或 recipe 提供默认值：

::: v-pre
```sh
# @arg 名称
NAME="{{.name}}"
```
:::

明确默认值为空字符串：

```sh
# @arg 名称
NAME=""
```

如果变量值是同名 Go template 占位符，例如 `NAME="&#123;&#123;.name&#125;&#125;"`，它只声明参数和说明，不提供 template 默认值。此时目录 `config.yaml.args` 或 recipe 可以提供默认值，二者都未提供时最终值为空字符串。

## 多行说明

说明文字可以用反斜杠连接：

```sh
# @description 安装 Docker Engine，\
# 并启动 docker 服务
```

参数说明也可以使用同样写法。

## 与 config.yaml 的关系

template 文件中的 `# @arg` 默认值会覆盖目录 `config.yaml.args` 中的同名默认值。template 注释元数据会覆盖目录 `config.yaml.metadata` 中的对应字段。

当你希望一组 template 共享默认值时，把默认值放在目录 `config.yaml`。当某个 template 自己有更强的默认值或元数据时，写在 template 注释中。

## 编写建议

- 保持脚本可直接阅读和审查。
- 用函数组织主体逻辑，避免顶层堆叠过长命令。
- 涉及 `sudo`、系统目录、服务重启、远程下载或破坏性修改时，在描述、元数据或脚本输出中写清楚。
- 不要把 template 写成不可审查的单条长命令。
- 不要把 framework 的外层组织逻辑写进 template。
