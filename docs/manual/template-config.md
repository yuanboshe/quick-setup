# template config 手册

`config.yaml` 固定表示 repo 根目录或 template 路径目录中的默认上下文文件。它不是 recipe 的默认入口文件名。

## 文件位置

`config.yaml` 可以出现在 repo 根目录，也可以出现在 template 所在路径的任一父目录。

```text
qs-repo/
  config.yaml
  docker/
    config.yaml
    install.sh
  nodejs/
    config.yaml
    install.sh
```

解析某个 template 时，QS 从 repo 根目录开始，按路径逐级读取存在的 `config.yaml`。

## 基本结构

```yaml
args:
  version: latest
  mirror: auto

metadata:
  description: 默认说明
  platform:
    - linux/ubuntu>=20.04
    - linux/debian>=11
  shell: bash
  requires:
    - sudo
    - curl
  effects:
    - package-install
  network:
    - download.example.com
```

规则：

- 参数默认值必须写在 `args` 中。
- 元数据默认值必须写在 `metadata` 中。
- 顶层普通字段不会作为参数读取。
- 文件不存在时直接跳过。

## args 合并

`args` 用于提供 template 参数默认值。

```yaml
args:
  version: latest
  mirror: https://example.com
```

合并顺序从低到高：

1. repo 根目录 `config.yaml.args`。
2. template 路径上每一级子目录的 `config.yaml.args`。
3. template 文件中的 `# @arg` 默认值。
4. recipe 中的 repo、目录和 template 覆盖项。

越靠近 template 的目录覆盖越上层目录。template 中明确写出的默认值会覆盖目录默认值。

## metadata 合并

`metadata` 用于描述 template 能力边界。

```yaml
metadata:
  platform:
    - linux/ubuntu>=22.04
  shell: bash
  requires:
    - sudo
    - apt-get
  effects:
    - package-install
  network:
    - download.docker.com
```

合并顺序从低到高：

1. repo 根目录 `config.yaml.metadata`。
2. template 路径上每一级子目录的 `config.yaml.metadata`。
3. template 文件中的 `# @description`、`# @platform`、`# @shell`、`# @requires`、`# @effects` 和 `# @network`。

recipe 当前不覆盖 metadata。

## 列表字段

`metadata.platform`、`metadata.requires`、`metadata.effects` 和 `metadata.network` 可以写成 YAML list，也可以写成按空白或逗号分隔的字符串。

```yaml
metadata:
  platform: linux/ubuntu>=22.04 linux/debian>=12
  requires: sudo,apt-get,curl
```

多级 config 的列表型 metadata 字段采用整体覆盖，不自动追加。显式空列表可以清空父级默认值。

```yaml
metadata:
  network: []
```

## description 与 shell

`metadata.description` 会进入 template 的 description 输出；template 文件中的 `# @description` 会覆盖它。

`metadata.shell` 是字符串：

```yaml
metadata:
  shell: bash
```

## 使用建议

- repo 根目录放全局默认值，例如通用平台、解释器或镜像源。
- component 目录放这一类 template 共享的默认参数和元数据。
- template 特有的参数默认值优先写在 template 中。
- 需要让 recipe 覆盖某个参数时，先在 `config.yaml.args` 或 template `# @arg` 中声明该参数。
- 不要把 recipe 内容写进 `config.yaml`。
