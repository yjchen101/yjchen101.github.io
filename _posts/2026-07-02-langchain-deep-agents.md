---
title: LangChain Deep Agents 深度解析
date: 2026-07-02 12:00:00 +0800
categories: [AI, Agent]
tags: [LangChain, DeepAgents, Agent, LLM, MCP]
description: LangChain Deep Agents 是一个集成了自主规划、上下文管理、工具调用、子 Agent、文件系统、记忆和技能的开箱即用通用 Agent 框架。本文从架构到实战全面解析。
---

## 1. 是什么

LangChain 开发的集成了 Agent 通用能力（自主规划、上下文管理、工具调用、子 Agent、文件系统、记忆、技能）的开箱即用通用 Agent 框架。

**定位：** Deep Agents 是建立在 LangChain/LangGraph 之上的**运行时/编排层（harness）**，让开发者不需要从零搭建 Agent 的底层基础设施。

**对比关系：**
- **LangChain** — 提供核心构建块（模型、工具、检索等）
- **LangGraph** — 提供有状态图执行引擎（持久化、流式、人机协同）
- **Deep Agents** — 基于 LangGraph 运行时的开箱即用 Agent 框架，内置规划、文件系统、子 Agent、记忆、技能等能力

**内置能力：**

| 能力 | 说明 |
|------|------|
| 环境动作（Take actions in an environment） | 通过工具调用、读写文件、执行代码 |
| 上下文管理（Context management） | 按需加载记忆、技能和领域知识 |
| 长上下文处理（Manage growing context） | 历史摘要、大结果卸载、跨长运行的上下文压缩 |
| 任务委派（Subagent spawning） | 委派给通用或专用子 Agent，运行在独立上下文窗口 |
| 人机协同（Human-in-the-loop） | 在关键决策点暂停等待人类审批 |
| 自适应学习（Learn and adapt） | 根据实际使用更新记忆、技能和提示词 |

## 2. 核心架构

### 执行环境（Execution Environment）四层

1. **工具层（Tools）** — 自定义函数、API、数据库
2. **虚拟文件系统层（Virtual Filesystem）** — 可插拔后端，支持文件读写、查找、编辑等操作
3. **文件系统权限（Filesystem Permissions）** — 声明式访问控制，控制 Agent 能读写哪些路径
4. **代码执行层（Code Execution）** — 沙箱化 Shell 执行 + 进程内 JS 解释器

### 上下文管理层（Context Management）四层

1. **技能（Skills）** — 按需加载的领域知识，从技能文件渐进式读取
2. **记忆（Memory）** — 跨会话持久化指令和偏好，启动时加载
3. **摘要与卸载（Summarization & Context Offloading）** — 自动压缩对话历史和大工具结果
4. **提示缓存（Prompt Caching）** — 静态提示段可缓存（Anthropic/Bedrock 默认启用）

### 委派层（Delegation）两层

1. **任务规划（Task tool）** — 结构化任务列表，持久的中间状态跟踪
2. **子 Agent（Subagent spawning）** — 临时子 Agent，独立上下文，隔离运行

### 控制层（Steering）两层

1. **人机协同（Human-in-the-loop）** — LangGraph interrupts，敏感工具调用前暂停审批
2. **文件系统权限（Filesystem Permissions）** — 声明式路径访问规则

## 3. 快速开始

```python
# pip install -qU deepagents langchain-google-genai

from langchain_deepagents import create_deep_agent
from langchain_google_genai import ChatGoogleGenerativeAI

def get_weather(city: str) -> str:
    """Get weather for a given city."""
    return f"It's always sunny in {city}"

agent = create_deep_agent(
    model="google_genai:gemini-3.5-flash",
    prompt="You are a helpful assistant",
    tools=[get_weather],
)

agent.invoke({"messages": [("human", "what is the weather in sf")]})
```

**支持的模型提供商：**
- `openai:gpt-5.5` / `anthropic:claude-sonnet-4-6` / `google_genai:gemini-3.5-flash`
- `openrouter:anthropic/claude-sonnet-4-6`
- `fireworks:accounts/fireworks/models/qwen3p5-397b-a17b`
- `baseten:zai-org/GLM-5.2`
- `ollama:devstral-2`

## 4. 工具调用 —— 注册与调用方式

### 4.1 工具注册方式

**方式一：提前全量注册**

```python
from langchain_deepagents import create_deep_agent

def my_tool(param: str) -> str:
    """Tool description."""
    return f"result: {param}"

agent = create_deep_agent(
    model="...",
    tools=[my_tool],  # 提前全量注册
)
```

**方式二：动态加载 MCP 工具**
Deep Agents 完整支持 [Model Context Protocol (MCP)](https://modelcontextprotocol.io)，通过 MCP 服务器动态加载工具：

```python
from langchain_deepagents import create_deep_agent
from langchain_mcp import load_mcp_tools

# 从 MCP 服务器加载工具（数据库、API、文件系统等）
mcp_tools = load_mcp_tools("mcp-server-url")

agent = create_deep_agent(
    model="...",
    tools=mcp_tools,  # 动态加载
)
```

工具可以是普通函数、`@tool` 装饰器函数或工具 dict。

### 4.2 内置工具（每个 Deep Agent 默认自带）

| 工具名 | 说明 |
|--------|------|
| `read_file` | 读取文件（支持分页和多模态） |
| `write_file` | 写入文件 |
| `edit_file` | 精确字符串替换 |
| `list_directory` | 列出目录内容 |
| `find_file` | 按模式查找文件 |
| `search_file` | 搜索文件内容 |
| `run_shell` | 运行 Shell 命令（需沙箱后端） |
| `task` | 维护结构化任务列表 |
| `delegate_to_subagent` | 创建子 Agent 委派任务（主 Agent 核心能力） |

### 4.3 多模态工具输出
工具可以返回文本 + 图像/音频/视频混合内容块，`read_file` 也支持多模态文件（图片、PDF 等）。

### 4.4 调用方式 —— 变成内部系统的运行时

Agent 构建后形成内部系统的运行时，通过 `agent.invoke()` 或 `agent.stream()` 调用，框架自动处理规划、工具路由、上下文管理等：

```python
# 同步调用
result = agent.invoke({"messages": [("human", "do something")]})

# 流式调用 —— 实时获取消息、工具调用、子 Agent 状态
for event in agent.stream({"messages": [("human", "do something")]}):
    # event 包含：消息、工具调用、工具结果、委派任务状态
    print(event)
```

## 5. Skill 与 Workflow 的区别

### Skill（技能）
- **是什么**：封装领域知识、工作流、最佳实践、脚本的可复用目录
- **结构**：每个 Skill 是一个目录，内含 `SKILL.md`（YAML frontmatter + Markdown 指令）+ 可选支持文件
- **加载机制**：**渐进式加载（Progressive Disclosure）**
  - 三级加载：
    1. **启动时**：只加载 Skill 名称和描述（frontmatter）到系统提示
    2. **调用时**：当任务匹配 Skill 描述时，读取完整 `SKILL.md` 指令
    3. **执行时**：指令中引用的支持文件按需加载
- **用途**：避免上下文膨胀，让 Agent 在需要时才获取完整知识
- **示例**：LangGraph 文档查询 Skill、PDF 处理 Skill、代码审查 Skill
- **共享性**：可在多个 Agent 和项目间共享，可组合多个 Skill

### Workflow（工作流）
- **是什么**：一系列预定义的、有序的执行步骤
- **粒度**：通常作为一个 Skill 的内容存在，写在 Skill 的指令中
- **关系**：Skill 可以**包含** Workflow 指令，但 Workflow 本身是 Skill 的**一部分**
- **编码化（Codify）**：当你发现自己在重复指导 Agent 做相同流程时，将其编码化为 Skill

### 对比总结

| 维度 | Skill | Workflow |
|------|-------|----------|
| 本质 | 可复用的能力包 | 执行步骤序列 |
| 粒度 | 粗（整个领域能力） | 细（具体步骤顺序） |
| 包含关系 | Workflow 是 Skill 的内容 | 是 Skill 的组成部分 |
| 加载方式 | 渐进式（两级延迟加载） | 随 Skill 一起加载 |
| 共享性 | 跨 Agent 跨项目 | 同 Skill 内复用 |

## 6. 自定义子 Agent

Deep Agents 支持创建专用子 Agent，为不同任务赋予不同能力：

```python
agent = create_deep_agent(
    model="anthropic:claude-sonnet-4-6",
    prompt="You are a helpful assistant",
    subagents=[
        {
            "name": "web_researcher",
            "description": "Used to research more in depth questions",
            "prompt": "You are a research assistant...",
            "tools": [web_search_tool],
            "model": "google_genai:gemini-3.5-flash",  # 可选覆盖
        }
    ],
)
```

**子 Agent 的关键特性：**
- 隔离上下文：子 Agent 有独立的上下文窗口
- 异步执行：主 Agent 不阻塞等待
- 单次通信：子 Agent 是**无状态的**，只能返回最终报告
- 上下文高效：中间步骤的数百次工具调用被压缩为一份结果
- 文件系统隔离：子 Agent 的文件系统与主 Agent 隔离
- 技能隔离：子 Agent 可以有自己独立的技能集

## 7. 人机协同（Human-in-the-loop）

基于 LangGraph 的中断机制，敏感工具调用前暂停审批：

```python
agent = create_deep_agent(
    model="...",
    interrupt_on={"edit_file": True},  # 编辑文件前暂停等待审批
)
```

支持：审批调用、修改工具输入、拒绝操作。

## 8. 记忆系统（Memory）

**文件系统驱动的记忆**：Agent 将记忆作为文件读写。

**作用域：**
- **Agent 作用域**：所有用户共享同一个记忆文件，Agent 构建自己的身份和累积知识
- **用户作用域**：每个用户有独立的记忆文件，用户偏好互不泄露
- **组织作用域**：跨所有用户和 Agent 共享的策略/知识

## 9. 事件流（Event Streaming）

```python
for event in agent.stream({"messages": [("human", "hello")]}):
    # 事件类型：消息、工具调用、工具结果、委派任务状态
    pass
```

每个委派子 Agent 有独立的事件句柄，支持消息、工具调用、嵌套子 Agent 的独立流。

## 10. 生产化（Going to Production）

- **LangSmith** 追踪、调试、评估
- **ACP（Agent Client Protocol）** — 通过 MCP 集成到 Claude、VSCode 等编辑器
- **自动重试** — Chat models 自动指数退避重试
- **沙箱后端** — SandboxBackendProtocolV2 支持隔离执行
