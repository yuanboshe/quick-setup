# recipe 手册

`recipe` 是 QS 的入口配置资产，负责声明组件库、framework 和本次要组合的 template。默认入口文件名是 `recipe.yaml`。

## 最小结构

```yaml
qs:
  repos:
    - path: .
      name: repo-name
  templates:
    - repo-name/component/hello.sh
```

`qs.templates` 和 `repos[].path` 是核心必填信息。`repos[].name` 和 `qs.framework` 可以由 QS 推理或回退，能省略时优先省略。

`qs.ghx` 默认开启，不写也等价于 `true`。只有需要完全保留原始 GitHub `curl` / `wget` 网络行为时，才设置为 `false`。

## qs 配置块

```yaml
qs:
  ghx: true
  repos:
    - path: .
      name: repo-name
  framework: framework.sh
  templates:
    - repo-name/component1_simple/hello.sh
    - component2_config_file/showtime.sh
    - component3_multi_files/hello.sh
    - bye.sh
```

字段说明：

- `qs.repos`：本次 recipe 使用的组件库列表。
- `repos[].path`：repo 路径，可以是本地绝对路径、本地相对路径、`git+` Git source 或 GitHub repo/tree URL。
- `repos[].name`：repo 逻辑名称，可省略；本地 repo 使用目录名，远程 Git repo 使用仓库名并去掉 `.git`。
- `qs.framework`：最终脚本外层模板，可省略；省略时使用内置默认 framework。
- `qs.ghx`：是否在生成脚本中启用 GHX runtime shim；默认 `true`，显式 `false` 时关闭。
- `qs.templates`：按顺序选择的 template 列表。

如果没有声明任何 repo，QS 会尝试使用 recipe 文件所在目录作为默认 repo。

## recipe 路径

常见输入：

```sh
qs inspect ./recipe.yaml
qs inspect https://github.com/owner/repo/blob/main/recipe.yaml
qs render
qs render ./example-repo
qs render git+https://example.com/org/qs-repo.git@v1.0.0
qs render git+https://example.com/org/qs-repo.git@v1.0.0//recipes/server.yaml
qs render https://example.com/recipes/server.yml
qs render https://example.com/recipes/
```

本地目录、Git source 和 HTTP(S) 目录 URL 未指定具体文件时，默认读取 `recipe.yaml`。明确指定文件名时，文件名不要求必须是 `recipe.yaml`。

## template ID

`qs.templates` 中每个条目按 `/` 切分。

完整写法：

```text
repo/template-dir/template
repo/docker/ubuntu/install.sh
```

完整写法至少三段，第一段匹配 repo name，中间所有段组成 template 目录，最后一段是 template 文件名。

相对目录写法：

```text
template-dir/template
template-dir/subdir/template
```

如果当前没有 repo name 且只有一个 repo，则使用该 repo；否则复用前一个 template 已确定的 repo。

一段写法：

```text
template
```

一段写法会复用前一个 template 已确定的 repo 和 template 目录。它适合连续选择同一目录中的多个 template。

template ID 不能使用空段、`.`、`..` 或绝对路径。多 repo 场景中，如果 QS 无法推断 repo，需要使用完整写法。

## 参数覆盖

recipe 可以覆盖 template 已声明的参数。参数名必须使用小写。

```yaml
repo-name/component3_multi_files:
  name: 目录级覆盖

repo-name/component3_multi_files/hello.sh:
  name: template 级覆盖
```

覆盖来源可以是：

- repo 级：`repo-name`
- 目录级：`repo-name/component`
- 多级目录级：`repo-name/component/subdir`
- template 级：`repo-name/component/template.sh`

参数覆盖顺序从低到高：

1. repo 根目录 `config.yaml.args`。
2. template 路径上每一级目录的 `config.yaml.args`。
3. template 文件中的 `# @arg` 默认值。
4. recipe 根部的 repo 覆盖项。
5. recipe 根部的目录覆盖项。
6. recipe 根部的 template 覆盖项。

recipe 不能覆盖无法匹配任何适用 template 的参数。可用参数来自 template 路径上的 `config.yaml.args`、template 文件中的 `# @arg`，以及同名自引用变量赋值，例如 `NAME="&#123;&#123;.name&#125;&#125;"`。

repo 级和目录级覆盖是默认值候选：只要覆盖范围内至少一个已选 template 声明该参数，其他未声明该参数的 template 会忽略它。template 级覆盖必须由该 template 自身声明参数。

## metadata 边界

recipe 当前只覆盖参数，不覆盖 metadata。metadata 描述 template 自身能力边界，包括平台、解释器、依赖、副作用和网络访问，应维护在 template 注释或 `config.yaml.metadata` 中。

## 远程 repo

recipe 中的 `repos[].path` 可以使用 Git source：

```yaml
qs:
  repos:
    - path: git+https://example.com/org/qs-repo.git@v1.0.0
      name: base
  templates:
    - base/docker/install.sh
```

普通 GitHub repo 或根 tree 页面链接也可以直接作为 repo path：

```yaml
qs:
  repos:
    - path: https://github.com/yuanboshe/qs-repo/tree/devel
      name: base
```

组件库必须是本地目录或 Git repo。不要把 HTTP(S) file source 写入 `repos[].path`。

## 远程 recipe

recipe 本身可以来自 Git source 或 HTTP(S) file source：

```sh
qs inspect git+https://example.com/org/qs-recipes.git@v1.0.0//server/recipe.yaml
qs inspect https://github.com/owner/repo/blob/main/server/recipe.yaml
qs inspect https://example.com/recipes/server.yaml
```

远程 recipe 会先缓存到本地，再继续解析。远程内容不会被当作 shell 文本直接执行。

GitHub repo 内 recipe 文件会优先复用已缓存的同 repo/ref snapshot；未命中时先下载单文件。如果 recipe 省略 `qs.repos`，或包含相对 `repos[].path`、`repos[].path: .`、相对 `qs.framework`，QS 会继续下载完整 repo snapshot 并使用 snapshot 内 recipe。

## 推荐写法

- 长期维护的 recipe 优先使用完整 template ID。
- 远程 Git source 优先写 tag 或 commit SHA。
- `qs.framework` 能省略时先省略，除非确实需要自定义脚本外层结构。
- recipe 只表达本次组合和参数，不把复杂流程逻辑写进 YAML。
