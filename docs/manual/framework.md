# framework 手册

`framework` 是最终脚本的外层模板。template 负责具体功能，framework 负责把已渲染的 template 组织成完整 shell 脚本。

## 最小示例

::: v-pre
```sh
#!/bin/bash

{{range $template := .templates}}
echo "-------------------- template {{$template.templateId}} --------------------"
{{$template.content}}
{{end}}
```
:::

framework 使用 Go `text/template` 渲染。

## 可用数据

当前 framework 注入数据为：

- `.templates`：已渲染 template 列表。
- 每个 template 包含 `templateId` 和 `content`。

示例：

::: v-pre
```sh
{{range $template := .templates}}
echo "template: {{$template.templateId}}"
{{$template.content}}
{{end}}
```
:::

## 适合放在 framework 的内容

- 脚本 header。
- 全局 shell 选项。
- template 分隔输出。
- 统一错误处理风格。
- 执行前后的提示信息。

## 不适合放在 framework 的内容

- 安装 Docker、配置 Node.js、修改系统文件等具体功能逻辑。
- 某个 template 私有的参数处理。
- 依赖某个 component 的业务流程。

这些内容应放在 template 或 recipe 中。

## framework 来源

`qs.framework` 可以使用：

- 本地绝对路径。
- 相对 recipe 文件所在目录的路径。
- repo 内路径。
- Git source。
- HTTP(S) file source。

示例：

```yaml
qs:
  framework: framework.sh
```

```yaml
qs:
  framework: repo-name/framework.sh
```

```yaml
qs:
  framework: git+https://example.com/org/qs-frameworks.git@v1.0.0//basic.sh
```

```yaml
qs:
  framework: https://example.com/frameworks/basic.sh
```

## 解析和回退规则

`qs.framework` 为空时，QS 使用内置默认 framework。

本地 framework 查找顺序：

1. 绝对路径直接检查。
2. 相对路径先以 recipe 文件所在目录为基准。
3. 如果路径第一段匹配 repo name，则以该 repo 目录为基准查找剩余路径。
4. 本地路径仍找不到时，回退到内置默认 framework。

显式远程 framework source 下载失败或解析后不是文件时，返回错误，不回退默认 framework。

## 使用建议

- 自定义 framework 应保持通用，不绑定某个具体安装任务。
- template 不应依赖 framework 的私有约定。
- 如果只是想组合不同功能脚本，优先改 recipe，不要改 framework。
- 如果只是想调整某个功能的命令内容，优先改 template，不要改 framework。
