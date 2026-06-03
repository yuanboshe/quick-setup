# repo 与 component 手册

`repo` 是 QS 的组件库，也是 Git 管理、发布、复用和信任边界。`component` 是 repo 下用于组织 template 的目录。

## 最小 repo

```text
qs-repo/
  docker/
    install_docker.sh
    install_compose.sh
  golang/
    install_go.sh
```

repo 可以只包含 component 和 template。`recipe.yaml`、`framework.sh` 和 `config.yaml` 都不是每个组件库的必需文件。

## 带示例的 repo

```text
qs-repo/
  recipe.yaml
  framework.sh
  config.yaml
  docker/
    config.yaml
    install_docker.sh
  golang/
    install_go.sh
```

这种结构适合同时提供可运行示例、默认 framework 和目录级默认上下文。

## repo 名称

recipe 中可以显式设置 repo name：

```yaml
qs:
  repos:
    - path: .
      name: base
  templates:
    - base/docker/install_docker.sh
```

省略 `name` 时，QS 会从 repo path 推断：

- 本地 repo 使用目录名。
- 远程 Git repo 使用仓库名并去掉 `.git`。

如果多个 repo 推断出的名称重复，QS 会返回错误，需要显式设置 `name`。

## component 分类

component 是分类目录，分类方式由维护者决定。

常见方式：

- 按软件：`docker/`、`nodejs/`、`golang/`
- 按系统能力：`apt/`、`service/`、`user/`
- 按场景：`server_init/`、`dev_env/`

component 可以有多级目录：

```text
qs-repo/
  docker/
    ubuntu/
      install.sh
    debian/
      install.sh
```

对应 template ID 可以写成：

```text
repo-name/docker/ubuntu/install.sh
```

## template 组织原则

- 一个 template 表达一个清晰功能意图。
- template 文件保持普通 shell 可读。
- 共享默认参数和元数据放在目录 `config.yaml`。
- 具体执行逻辑放在 template，不放在 framework。
- 示例 recipe 可以放在 repo 根目录，但不要把 repo 设计成只能服务一个 recipe。

## 远程 repo

recipe 可以引用 Git source：

```yaml
qs:
  repos:
    - path: git+https://example.com/org/qs-repo.git@v1.0.0
      name: base
  templates:
    - base/docker/install.sh
```

Git source 支持：

```text
git+<git-url>.git
git+<git-url>.git@<ref>
git+<git-url>.git@<ref>//<recipe-path>
```

作为 `repos[].path` 时，QS 使用其中的 repo；`//<recipe-path>` 对 repo cache 命令会被忽略。组件库必须是本地目录或 Git repo，不能是 HTTP(S) file source。

## 发布建议

- 远程 repo 建议提供 tag 或 commit SHA 供 recipe 使用。
- 修改 template ID、参数名或默认行为前，考虑已有 recipe 的兼容性。
- 涉及系统修改、远程下载或高权限操作的 template，应维护好 `# @description` 和元数据。
- 删除或重命名 template 前，优先提供迁移说明。

## 检查清单

- repo 是否能作为独立组件库被理解。
- component 分类是否清楚。
- template 是否能被人类直接审查。
- 参数是否通过 `# @arg` 或 `config.yaml.args` 声明。
- 元数据是否覆盖平台、解释器、依赖、副作用和网络访问。
- recipe 中是否使用清晰的 template ID。
