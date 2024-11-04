# 快速开始

## 核心命令

```bash
# 基于当前路径的配置文件（./config.yaml）生成自动化脚本（./quick-setup.sh）
qs

# 设置配置文件路径及文件名，默认：./config.yaml
qs </the/config-file/path/filename.yaml>

# 设置自动化脚本的输出路径及文件名，默认：./quick-setup.sh
qs -o/--output </the/output/path/filename.sh>

# 不生成自动化脚本文件，而是直接执行自动化脚本
qs -r/--run

# 导出example-repo到指定路径
qs -e/--example .
```

## 组件库

本仓库是组件库的示例，以及用于发布quick-setup二进制文件，暂时不打算开源quick-setup源码，但承诺开放免费使用。

组件库目录结构如下：

```bash
quick-setup # 组件库
├── component1 # 组件名
│   ├── config.yaml # 默认配置
│   ├── hello.sh # 功能模板
│   └── bye.sh # 功能模板
├── component2
│   ├── config.yaml
│   └── showtime.sh
├── config.yaml # qs的配置文件，可以放在任意位置，放这里只是提供配置参考
└── framework.sh
```

组件库是一个文件夹，包含一系列组件。

## 组件

每个组件是一个文件夹，文件夹名即组件名，包含一个默认配置文件（config.yaml）和多个功能模板（脚本）文件。

默认配置文件（component1/config.yaml）示例如下：

```yaml
arg: # 表示组件参数
  example_param: default example param # 任意需要修改的参数
```

组件下的config.yaml文件，默认配置文件内的arg参数，如果有缺失，则默认组件无参数，不影响组件内模板的加载。

功能模板示例如下（hello.sh）：

```bash
echo "hello {{.example_param}}"
```

功能模板中可以使用`{{.example_param}}`来引用配置文件中的参数，也可以编写逻辑处理，语法参考golang template。

## qs配置文件

可以放在任意位置，放这里只是提供配置参考。用于指导quick-setup工具生成自动化脚本。 同时，qs配置文件能够配置组件参数，用来覆盖组件默认配置文件中的参数。

config.yaml示例：

```bash
qs:
  repos:
    - path: .
      name: repo-name
  framework: framework.sh
  templates:
    - repo-name/component1/hello.sh
    - component2/showtime.sh
    - component1/bye.sh

repo-name/component1:
  name: |-
    qs name
      with multi lines
```
