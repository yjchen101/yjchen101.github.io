---
title: DeerFlow 架构解析
date: 2026-08-03 12:00:00 +0800
categories: [开源]
tags: [DeerFlow, 架构, Agent, MCP]
---

# DeerFlow 架构解析

## 1. Provider：大模型 API 统一抽象

> 目标：适配各种大模型厂商的 API，在 LangChain 基础上提供统一抽象。

- **适配器模式（Adapter）**：将不同厂商的 API 统一成 `BaseChatModel`
- **工厂模式（Factory）**：解决对象生成问题 —— 根据不同的配置生成不同的对象
- **策略模式（Strategy）**：灵活替换不同的调用策略

### 关于 Completions 和 Responses 协议

1. 原来的 Completion 是无状态的，每个调用接口都有之前的对话没有关系，包括 tool calling
2. 有状态，服务器可以存储上下文，同时内置工具

## 2. 多 Agent 系统设计

是什么？主agent+子 agent，减少主 agent 的上下文占用，

怎么做？通过工具调用进行派发，如何通信呢?

## 3. MCP 工具

- **概述**：根据工具配置**发现工具**，建立本地 `mcp client → mcp server` 的配置；将 MCP Server 暴露的 `tool / resource / prompt` 改造成可直接使用的对象。
  - **拦截器（Interceptor）**：负责在工具调用前后进行拦截
  - **配置加载**：LangChain 将配置文件 → 对象
  - **连接模型**：默认情况下每次都要重新建立连接，它是**无状态的**
  
- **工具发现与缓存**：`client.get_tools()` 会被缓存，但**每次发起对话都会重新走一遍该过程**：
  
  ```
  每个 Server：
      建立临时连接 → initialize → list_tools → 转换为 LangChain Tool → 关闭连接
  ```
  
- **鉴权**：如何鉴权？

  #### 重试机制

  当前是失败直接返回 bad tool message，也可以有更加灵活的处理方式，滑动窗口 失败重试次数？ 按照类型？ 

  - 工具重复调用（相同的参数，不同参数？）
  - 工具调用失败

  统计方式:

  - 滑动窗口统计，hash+工具名称统计

  警告和停止分别是如何实现的

  1. 当工具调用超过阈值之后，会等工具调用执行完之后等下一次模型调用加入一条human message，不能立即加

     ```
       HumanMessage(user question)
       AIMessage(tool_calls=[...])
       ToolMessage(tool result 1)
       ToolMessage(tool result 2)
       HumanMessage(
         name="loop_warning",
         content="[LOOP DETECTED] You are repeating the same tool calls. ..."
       )
     ```

     2. 停止，

- **传输方式**：`stdio` 和 `sse/http`

- **有状态 vs 无状态**：支持有状态 session

- **文件系统对接**：MCP 文件输出对接文件系统

## 4. 可观测性

## 5. Runtime

- 文件上传：将文件放到虚拟文件系统当中，把路径暴露给大模型即可
- 

## 6. 安全配置

- 沙箱机制
- 

## 7. 记忆系统
