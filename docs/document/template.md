# 功能脚本

## qs标记

qs可以对功能脚本进行解析，依照qs标记指示的功能进行处理。所有的qs标记都写在注释内，由 `# @` 开头，前面可以有空白字符，后面紧跟标记name，再后面则空格为标记的description。

如变量标记 `# @arg this is a demo` 表示标记名为 `arg`，标记描述为 `this is a demo`。

### @description

功能脚本的描述。

```bash
# @description ...
```

### @arg

配置变量。

```bash
# @arg ...
NAME="default name"
```

在外部配置文件中设置的 `name` 变量将会替换掉标记有 `@arg` 的变量值。

例如，yaml配置文件中：

```yaml
arg:
  name: config name
```

qs会将功能脚本中的 `@arg` 下面出现的第一行赋值语句中的同名变量的值进行替换，如上面赋值语句将会被替换为 `NAME="config name"`。

注意：

1. 配置文件中的变量名必须全小写，将会匹配脚本中的任意大小写变量名，如上例的 "Name", "NAME", "nAmE" 都是等效的。
2. 如果配置文件中没有设置替换变量，将保持脚本中的默认值。
3. 脚本中可以是双引号 `"`，单引号 `'`，或者是无引号，配置文件中进行变量替换后保持脚本中的引号书写形式不变。
4. qs会寻找 `@arg` 下面第一个出现的赋值语句，中间可以有空行，赋值语句识别为 `变量名=变量值` ，赋值语句前面可以有空字符，变量值可以为空。

### 多行注释

如果描述太长，可以在行的末尾使用 `\` 结尾，表示与下一行注释进行拼接（下一行注释的 `#` 前的空白字符，或者后1个空格会被忽略），如：

```bash
# @description this is the description of the script file \
# you can write multiple lines with "\" at the end of each line
```

## 样例

### 最简单的格式

```bash
# @arg this is the description of arg
NAME="default name"

echo "hello [${NAME}]"
```

与普通的shell脚本一致，只是对于要引用外部配置文件变量的赋值语句，在上面添加注释 `# @arg ...` 即可。

### 推荐的格式

```bash
#!/bin/bash

# @arg this is the description of arg
NAME="default name"

# main
main() {
  echo "hello [${NAME}]"
}

main
```

用函数进行包裹，逻辑更加清晰。