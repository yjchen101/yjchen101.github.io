---
blog_id: pi-architecture-streaming
permalink: /posts/pi-architecture-streaming/
title: Pi 架构解析：pi-ai 与 pi-agent-core 的流式事件设计
date: 2026-08-18 12:00:00 +0800
categories: [AI, Agent]
tags: [Pi, pi-ai, pi-agent-core, 流式处理, 工具调用]
description: 本文从 pi-ai 与 pi-agent-core 的分工出发，解析基于 partial 快照的流式事件设计以及 Agent 工具调用闭环。
---

## 总体

核心就是两个部分

- pi-ai 如何和不同的大模型来交互
- Pi-agent-core 就是 agent loop

### 关于流式处理的设计

##### 方案一：传统增量流（只传 Delta）

```typescript
// 1. 你必须自己在外部维护所有状态！
let fullThinking = "";
let fullText = "";
let isThinking = false;

// 2. 监听增量事件
stream.on("thinking_delta", (delta) => {
    // 你要记住当前在拼哪一块
    fullThinking += delta;
    // 渲染时，要把 thinking 和 text 拼成一个完整对象
    renderUI({ thinking: fullThinking, text: fullText });
});

stream.on("text_delta", (delta) => {
    fullText += delta;
    // 每次都要把两个变量组装起来
    renderUI({ thinking: fullThinking, text: fullText });
});

// 3. 如果中途收到重连或乱序，你还得处理边界情况...
// 风险：如果少收到一个 delta，你的 fullText 就永远缺个字。

```

##### 方案二：pi-ai 的状态流（携带 Partial）

**无需维护状态，拿到的就是完整的当前快照。**

```typescript
// 1. 不需要声明任何外部变量来拼接！
for await (const event of eventStream) {
    // 2. 直接使用 event.partial，它已经包含了截止到当前的所有信息
    // 无论是 thinking 还是 text，都在这个对象里整整齐齐地放着。
    const currentMessage = event.partial;

    // 3. 直接拿去渲染，永远不用担心拼错或漏字
    renderUI(currentMessage);
}

// 甚至你可以在任意时刻中断循环，拿到的 partial 也是完整的
// 而不像方案一，中断循环后你只能拿到残缺的字符串。
```

### eventstream

```typescript
type AssistantMessageEvent =
  | { type: "start"; partial: AssistantMessage }
  | { type: "text_start"; contentIndex: number; partial: AssistantMessage }
  | { type: "text_delta"; contentIndex: number; delta: string; partial: AssistantMessage }
  | { type: "text_end"; contentIndex: number; content: string; partial: AssistantMessage }
  | { type: "thinking_start"; contentIndex: number; partial: AssistantMessage }
  | { type: "thinking_delta"; contentIndex: number; delta: string; partial: AssistantMessage }
  | { type: "thinking_end"; contentIndex: number; content: string; partial: AssistantMessage }
  | { type: "toolcall_start"; contentIndex: number; partial: AssistantMessage }
  | { type: "toolcall_delta"; contentIndex: number; delta: string; partial: AssistantMessage }
  | { type: "toolcall_end"; contentIndex: number; toolCall: ToolCall; partial: AssistantMessage }
  | { type: "done"; reason: "stop" | "length" | "toolUse"; message: AssistantMessage }
  | { type: "error"; reason: "aborted" | "error"; error: AssistantMessage };
```

主要包括两个内容：

- 内容：text_start，text_delta，text_end
- 控制：start,done,error

````
start → [thinking_start → delta... → end] → [text_start → delta... → end] → [toolcall_start → delta... → end] → done
````



##### 完整的工具调用流程

```
用户: "北京天气怎么样？"
   ↓
① [AI 接收请求]
   ↓
② [流式事件触发]
   start → toolcall_start → toolcall_delta... → toolcall_end → done (reason: "toolUse")
   ↑                                                ↑
   |                                       携带完整的 toolCall 对象
   |                                       (name: "get_weather", args: {city: "北京"})
   |
③ [你的应用层代码拦截]
   检测到 done.reason === "toolUse"
   → 立即执行真实的 API 调用（比如去查天气接口）
   → 拿到结果："{ temperature: 25, condition: '晴' }"
   ↓
④ [发起第二次流式请求（把结果喂给 AI）]
   stream(model, {
     messages: [
       ...历史消息,           // 包含刚才那条带 toolCalls 的 AssistantMessage
       { role: "tool", content: "{ temperature: 25 }", toolCallId: "xxx" }
     ]
   })
   ↓
   ⑤ AI 拿到结果后，生成最终回复：
   start → text_start → text_delta... → done (reason: "stop")
   最终渲染到屏幕: "北京今天晴天，气温25摄氏度。"
```

## 参考资料

- [深度解析：pi-ai 与 pi-agent-core](https://guangzhengli.com/notes/pi-ai-and-agent-core-course#22-provider-%E6%B3%A8%E5%86%8C%E6%9C%BA%E5%88%B6)







<!--
发布前检查：

- 修改 title、date、categories、tags 和 description
- 补充正文，删除无关章节
- 将所有外部资料写成 Markdown 链接
- 只修改当前源文件，不要直接编辑博客仓库的 _posts 快照
-->
