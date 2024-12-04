# 菜单配置

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
  name: my component name in cookbook file

repo-name/component1/hello.sh:
  name: my template name in cookbook file
```

`qs.repos`表示需要引用的组件库列表。其中`path`是组件库的本地地址，可以是绝对路径，也可以是相对路径（相对菜单）；`name`是组件库的别名，后面会用来做引用标识。
`qs.framework`表示使用的框架模板文件路径，可以是绝对路径，也可以是相对路径（相对菜单），还可以是相对组件库（用别名标识）下的路径。如`repo-name/framework.sh`表示repo-name组件库下的framework.sh文件。并且，`qs.framework`参数不是必须，可以为空，如果工具找不到配置的框架模板，就会使用代码空间内置的框架模板。
`qs.templates`表示功能脚本的列表，这是一个有序的string列表，工具会依照这个顺序组装最终的应用脚本。列表内容就是功能脚本的ID（“组件库名/组件名/功能脚本名”），然而，在填写时为了方便，只有第一个功能脚本ID需要写全，如果接下来的功能脚本和上一个具有相同的“组件库名”或者“组件名”，都可以省略掉，工具会自行补全。

如果需要修改功能脚本的变量，可以直接在下面添加要覆盖的变量，格式是以功能脚本ID（“组件库名/组件名/功能脚本名”）起头，后接变量名和变量值。当然，也可以添加针对组件所有功能脚本的变量，格式是以组件ID（“组件库名/组件名”）起头，后接变量名和变量值。

菜单的作用，就像客户点菜一样，在“菜单”上勾出自己需要的菜品，标记做成什么味道，然后下单即可。quick-setup工具最基本的用法，就是`qs </the/config-file/path/filename.yaml>`，即命令+菜单，quick-setup会根据菜单生成最终的应用脚本。