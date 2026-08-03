---
title: DeerFlow 架构解析
date: 2026-08-03 12:00:00 +0800
categories: [开源]
tags: [DeerFlow, 架构, Agent, MCP]
---

## 1. Provider：大模型 API 统一抽象

> 目标：适配各种大模型厂商的 API，在 LangChain 基础上提供统一抽象。

- **适配器模式（Adapter）**：将不同厂商的 API 统一成 `BaseChatModel`
- **工厂模式（Factory）**：解决对象生成问题 —— 根据不同的配置生成不同的对象
- **策略模式（Strategy）**：灵活替换不同的调用策略

## 2. 多 Agent 系统设计

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

- **重试机制**：当前是失败直接返回 bad tool message，

- **传输方式**：`stdio` 和 `sse/http`

- **有状态 vs 无状态**：支持有状态 session

- **文件系统对接**：MCP 文件输出对接文件系统

## 4. 可观测性

## 5. Runtime

## 6. 安全配置

## 7. 记忆系统