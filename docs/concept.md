# 相关概念

我们以example-repo为例子介绍相关概念：

```bash
example-repo        # 组件库
├── component1      # 组件
│   ├── bye.sh      # 功能模板
│   ├── config.yaml # 默认配置
│   └── hello.sh
├── component2
│   ├── config.yaml
│   └── showtime.sh
├── config.yaml     # 菜单（配置）
└── framework.sh    # 框架模板
```

## 功能脚本（功能模板）

功能脚本指完成某项特定功能的脚本，比如安装docker、修改更新源、测试多个镜像地址的连接速度等。

功能脚本也可以拆解成yaml配置文件+脚本模板的形式，此时功能脚本变成了功能模板，如下面的例子 *hello.sh*：

```bash
# params
NAME="{{.name}}"

# main
echo "hello ${NAME}"
```

对应的参数配置文件 *config.yaml* 为：

```bash
arg:
  name: default name
```

`qs`命令会将配置文件下 *arg* 里面的参数注入功能模板内。

注意：配置文件名字必须是 *config.yaml* ，需要注入的参数都必须放在 *arg* 参数下面。

## 框架模板

框架模板是最终应用脚本的框架，功能脚本会依次被注入框架模板内。框架模板是写得简单还是复杂，以及如何组织功能脚本，由设计者自己定义。

例如下面的简单框架模板：

```bash
#!/bin/bash

echo "==================== Start ===================="
{{range $index, $template := .templates}}
echo "-------------------- template {{$template.templateId}} --------------------"
{{$template.content}}
{{- end}}
echo "==================== End ===================="
echo "All works finished!"
```

其中`.templates`是功能脚本的有序列表，每个template都包含`templateId`（/组件仓库名/组件名/功能模板名）和`content`功能脚本内容。

## 组件

组件就是包含一个或者多个功能模板，组件配置文件的文件夹，文件夹的名字就是组件的名字。

组件是一个分类的概念，具体如何分类完全由功能脚本的维护者自行决定。

## 组件库

组件库是包含一个或者多个组件的文件夹（可以只包含组件而不需要任何其他文件），是比组件更高一级的分类，Git版本管理是以组件库为单位进行管理的。

## 菜单（配置文件）

“菜单”是yaml格式的配置文件，quick-setup跟进菜单的配置来生成最终的应用脚本。

典型的菜单配置文件及参数说明如下：

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

`qs.repos`表示需要引用的组件库列表。其中`path`是组件库的本地地址，可以是绝对路径，也可以是相对路径（相对菜单）；`name`是组件库的别名，后面会用来做引用标识。
`qs.framework`表示使用的框架模板文件路径，可以是绝对路径，也可以是相对路径（相对菜单），还可以是相对组件库（用别名标识）下的路径。如`repo-name/framework.sh`表示repo-name组件库下的framework.sh文件。并且，`qs.framework`参数不是必须，可以为空，如果工具找不到配置的框架模板，就会使用代码空间内置的框架模板。
`qs.templates`表示功能模板的列表，这是一个有序的string列表，工具会依照这个顺序组装最终的应用脚本。列表内容就是功能模板的ID（“组件库名/组件名/功能模板名”），然而，在填写时为了方便，只有第一个功能模板ID需要写全，如果接下来的功能模板和上一个具有相同的“组件库名”或者“组件名”，都可以省略掉，工具会自行补全。

如果需要修改功能模板的参数，可以直接在下面添加要覆盖的参数，格式是以组件ID（“组件库名/组件名”）起头，后接参数名和参数值。

菜单的作用，就像客户点菜一样，在“菜单”上勾出自己需要的菜品，标记做成什么味道，然后下单即可。quick-setup工具最基本的用法，就是`qs </the/config-file/path/filename.yaml>`，即命令+菜单，quick-setup会根据菜单生成最终的应用脚本。
