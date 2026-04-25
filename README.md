# 解决clangd重命名符号失败的问题

## 用法

将ccc.ps1复制到c/c++项目根目录，然后将"CMakeList.txt"的内容粘贴到项目根CMakeLists.txt里（project命令前）

根据需要更改ccc.ps1中的compile_commands.json的路径。

## 原理

ccc.ps1会将compile_commands.json中所有大写字母的盘符转换为小写形式，例如：将E://转换为e://。
