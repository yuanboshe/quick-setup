# 组件库与组件

## 组件库

组件库是git版本管理的单位，包含组件及功能脚本。最简单的组件库的目录结构及说明如下：

```bash
example-repo        # 组件库
├── component1      # 组件
│   ├── bye.sh      # 功能脚本
│   └── hello.sh
├── component2
│   └── showtime.sh
```

如上，新建一个 *example-repo* git仓库，在下面新建文件夹即为组件，然后以组件库位版本管理单位。

## 组件

组件是组件库下面的文件夹，包含一系列相关的功能脚本，具体如何分类因人而异。

组件可以包含配置文件（也可以没有），默认名字为 *config.yaml* ，主要是为以后拓展组件的功能（目前只能向功能脚本注入默认变量值）。

如果希望向组件下的所有功能脚本注入变量，可以写成：

```yaml
arg:
  name: my component name in component file
```

`qs`命令会将配置文件下 *arg* 里面的变量 *name* 注入到功能脚本内，即用 `arg.name` 的值替代前面 *hello.sh* 脚本中的 `NAME` 的值。

注意：配置文件中的变量名必须全部小写，匹配功能脚本中任意大小写的变量名，即 `name` 可以匹配 `NAME`, `Name`, `nAmE`等，在功能脚本中通过添加 `# @arg` 头，表示改变量的值可以被配置文件中的值替代。

如果只希望向 *hello.sh* 脚本注入变量，可以写成：

```yaml
arg/hello.sh:
  name: my template name in component file
```

这里脚本级的配置变量会覆盖前面组件级的配置变量，两者都会生效，只是会有同名覆盖。
