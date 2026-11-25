---
blog_id: c-language-syntax
permalink: /posts/c-language-syntax/
title: C 语言语法
date: 2026-11-25 22:00:00 +0800
categories: [C]
tags: [C, 语法, 指针, 关键字]
---

## 几个关键词

1. **const**：常量指针和指针常量（`const int *p`）和（`int *const p`）
2. **static**：文件内全局变量
3. **volatile**：禁用编译器的寄存器缓存优化，多核处理器还有对应的多级缓存
4. **define 和 inline 的区别**
5. **extern**：用来使用已经定义过的全局变量

## 初始化时序

C 语言中 static 会在程序开始之前完成初始化：

- 初始化，在程序开始之前必须初始化；
- 赋值。

```c
Fun(int a) int arr[a] = {};
int arr[a];
memset()
```

## 声明和定义

- `int a` 声明
- `int a = 10` 声明 + 定义

## 整型与类型转换

- 大类复制给小类：截断，不一定，看编译器实现
- 注意：无符号整数运算溢出是有明确定义的，按照模 $2^N$
- 有符号 → 无符号
- **无符号赋值给有符号**

## 枚举

枚举类型可读性更高。

```c
typedef enum {
    SSD_IDLE,
    SSD_READING,
    SSD_WRITING,
    SSD_ERROR
} SSD_STATE;

SSD_STATE state = SSD_IDLE;

if (state == SSD_READING) {
    // 正在读取
}
```

## 宏定义

1. 每个参数使用括号包裹。
2. 整个表达式使用括号包裹。

**宏不仅可以使用自己定义的参数，还可以直接使用外部已经存在的变量、宏和其他标识符。**

宏展开之类的：

```c
#define MUL(a, b) a * b

int result = MUL(2 + 3, 4 + 5);
```

## switch 与 ifelse

- 代码结构更清晰
- 如果是连续的话，可以优化成索引表，方便通过索引直接跳转

## typedef 与自引用结构体

```c
typedef struct node
{
    int data;
    struct node;
}Node;

typedef struct
{
    int data;
    struct node;
} Node;   第一种可以自引用，第二种不行 只能使用 Node的形式
```

## void*

`void*` 单纯保存地址，不知道类型，我们可以人为做类型转换，让他根据这个类型解释二进制流。

## 指针与类型

- 指针和引用（对象的别名，强制初始化）的区别：引用可以零成本地传递对象，同时还能保证安全，可读性更高。
- NULL（预定义宏）和 nullptr（关键字）的区别。
- `sizeof` 的原理：编译时期计算的。
- 指针和数组的区别。
- 数组名是常量指针。

## 资料

1. [C/C++ 面试资料](https://github.com/huihut/interview)
2. [小林 coding](https://www.xiaolincoding.com/)
