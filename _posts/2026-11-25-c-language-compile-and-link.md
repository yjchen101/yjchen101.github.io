---
blog_id: c-language-compile-and-link
permalink: /posts/c-language-compile-and-link/
title: C 语言编译链接与内存分段
date: 2026-11-25 22:00:00 +0800
categories: [C]
tags: [C, 编译链接, 内存分段, 嵌入式]
---

## C 程序的内存结构

1. 静态段（数据和 bss（初始化全为 0 和未初始化的，节约可执行文件大小）），编译时确认
2. 代码段
3. Heap
4. Stack

## 只读查找表写成 const，为什么有时仍占 RAM，怎样让它留在 Flash？

1. Const 只保证程序不该写，放哪段由链接脚本决定。
2. 有的工程会把只读段也拷进 RAM，换访问速度，表一大就挤占内存。
3. 要留在 Flash，就把该段映射到只读区，启动代码不要再拷贝它。
4. 表如果要给 DMA 当源，先确认 DMA 能不能读 Flash；不能的话才有理由拷到 RAM。
5. 改段之后看 map 文件，确认符号落在 Flash 地址而不是 RAM。
