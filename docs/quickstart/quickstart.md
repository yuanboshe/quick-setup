# 快速开始

## 安装

quick-setup是一个二进制可执行文件，从[github release](https://github.com/yuanboshe/quick-setup/releases)页面下载后放在适当的位置即可。

也可以使用下面的*install.sh*脚本完成自动化安装，脚本会自行判断系统是amd64还是arm64平台。文件只有不到5M，安装通常在1分钟内完成，如果因为网络或者代理问题，可以重试或者切换代理。

### 墙外安装

```bash
curl -sSL https://raw.githubusercontent.com/yuanboshe/quick-setup/master/scripts/install.sh | bash
```

### 墙内指定代理安装

```bash
PROXY=https://ghp.ci/ && curl -sSL "${PROXY}https://raw.githubusercontent.com/yuanboshe/quick-setup/master/scripts/install.sh" | bash -s -- "$PROXY"
```

### 自行判断是墙外还是墙内安装

```bash
PROXY=$(curl -s -I -m 5 https://www.google.com >/dev/null 2>&1 && echo "" || echo "https://ghp.ci/") && curl -sSL "${PROXY}https://raw.githubusercontent.com/yuanboshe/quick-setup/master/scripts/install.sh" | bash -s -- "$PROXY"
```

### 验证

```bash
# 版本信息
qs -v

# 帮助
qs -h
```

## 基础指令

### 导出仓库模板

quick-setup安装完成后有且仅有一个 *qs* 二进制文件，为了方便参考，代码空间内置了仓库模板，可以直接使用 *-e/--example* 选项导出。

```bash
# 导出example-repo到指定路径
qs -e .
```

-e选项后面的参数表示 *example-repo* 的导出路径，可以是相对（当前目录）路径，也可以是绝对路径。

example-repo的目录结构及说明如下：

```bash
example-repo        # 组件库
├── component1      # 组件
│   ├── bye.sh      # 功能脚本
│   └── hello.sh
├── component2
│   └── showtime.sh
└── config.yaml     # 菜单配置
```

基本的组件库包含组件、功能模板、默认配置三部分。而example-repo中的菜单和框架模板可以放在任何地方，不是组件库的必须组成部分，放在这里只是提供参考。

### 生成脚本

有了组件仓库后，就可以基于组件仓库和菜单生成脚本了，使用指令 `qs </the/config-file/path/filename.yaml>` 完成。

例如，前面的example-repo路径为 */home/pz1/example-repo/* ，则执行指令：

```bash
qs /home/pz1/example-repo/config.yaml
```

执行完成后，会在当前目录下生成脚本 *quick-setup.sh* 可以直接执行 `./quick-setup.sh` 查看运行效果。

其中，路径可以是相对（当前目录）路径，文件名 *config.yaml* 也可以省略（会默认查找路径下的该菜单文件）。并且，如果当前路径下就有菜单文件 *config.yaml* ，则命令可以直接简化为 `qs`，不需要附带任何参数。

### 指定脚本输出路径

*-o/--output* 选项可以将可执行脚本输出到指定的路径及文件名。

例如，如果希望输出到 */home/pz1/test.sh* 可以使用指令：

```bash
qs /home/pz1/example-repo/config.yaml -o /home/pz1/test.sh
```

同样，-o选项后面的路径参数可以是相对路径，但必须指定文件名。

### 不输出脚本而直接执行

*-r/--run* 选型不附带任何参数，表示不输出脚本，而是直接执行脚本。

例如，如果希望按照 */home/pz1/example-repo/config.yaml* 菜单的指示装配脚本，但是不生成脚本文件而是直接执行脚本，可以使用指令：

```bash
qs /home/pz1/example-repo/config.yaml -r
```

## 最后

quick-setup的核心目标旨在解决shell脚本结构化设计复杂，难维护，难复用，难管理的问题。通过对复杂脚本的概念抽象，变成容易维护的功能模板，然后按照一定的规范进行组织，最后由quick-setup组装成面向复杂场景的可执行脚本呈现给用户。

具体如何实现上述目标，需要用户通过后续章节了解相关组织规范，维护自己的组件仓库，或者编写面向特定场景的“菜单”。

同时，quick-setup还有一个很重要的设计理念——**简单，简单，还是简单**，力求实现**低学习成本快速上手**。
