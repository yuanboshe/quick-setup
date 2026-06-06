# Agent Skills

当前发布两个 quick-setup Agent skill。skill 真源放在仓库一级目录 `skills/` 下，方便从 GitHub 项目首页直接发现；文档站构建时会从该目录生成 raw 下载文件。

默认安装脚本会把这些 skill 安装到 `${AGENTS_HOME:-~/.agents}/skills`，并在检测到 Codex 或 Claude 用户目录时创建引用。Windows 下会优先使用目录 junction。需要跳过时，在安装 QS 时设置 `QS_INSTALL_SKILLS=false`。

仓库入口：

```text
https://github.com/yuanboshe/quick-setup
```

## qs-cmd

用途：当用户提出复杂软件部署、环境配置、系统初始化或多步骤 shell 操作目标时，让 Agent 优先发现并复用已有 QS template，通过简单 recipe 完成自动化任务；同时约束 Agent 如何调用、解释和记录 QS 命令。

下载路径：

```text
https://qs.pz1.top/skills/qs-cmd/SKILL.md
```

仓库路径：

```text
skills/qs-cmd/SKILL.md
```

## qs-repo

用途：当一系列自动化部署、环境配置或系统初始化流程需要复用时，让 Agent 将操作意图沉淀为 QS 组件资产；同时约束 Agent 如何创建、修改、审查和说明 QS 组件库。

下载路径：

```text
https://qs.pz1.top/skills/qs-repo/SKILL.md
```

仓库路径：

```text
skills/qs-repo/SKILL.md
```
