---
# the default layout is 'page'
icon: fas fa-info-circle
order: 4
---

## 教育背景

**广东工业大学** · 计算机技术 · 在读硕士研究生 \
2024.9 - 至今

**安徽信息工程学院** · 数据科学与大数据技术 · 工学学士 \
2019.9 - 2023.6

---

## 项目经历

### Vibe Blog
**Agent 开发** · Python / Flask / LangGraph / LangChain / SQLite / SSE

**项目简介**: 针对传统技术博客创作中存在的调研耗时、配图门槛高和内容浅显等痛点，开发了基于多智能体协作的 vibe-blog 平台。该项目打造了集"调研-规划-撰写-配图-审核-排版"于一体的自动化流水线，将长文本创作从全人工组装升级为智能体分工协同，大幅降低高质量技术内容的创作门槛与时间成本。

**主要内容**:
- **多智能体状态机编排**: 基于 LangGraph 构建状态图，设计 Researcher、Planner、Writer、Reviewer 等角色与条件路由，支持 Human-in-the-loop 的交互式大纲确认（Interrupt/Resume），解决长任务生成不稳定、流程难扩展的问题。
- **长任务全链路可观测**: 设计 TaskManager 结合 SSE 事件流，实现分阶段实时推送、状态查询和异步任务取消，让耗时生成过程从黑盒变为透明可控。
- **并行化与异步调度**: 采用多线程并行执行多章节写作与检查，将配图任务解耦为异步后台执行，通过 Future/Promise 汇总结果，减少关键路径阻塞，提升整体吞吐量。
- **自动化质量控制**: 引入 Questioner、Reviewer、Factcheck 等质检智能体，基于状态流转按需触发深度追问与迭代修正，有效降低单次生成的内容缺陷，减少人工返工。

### 本地生活服务平台
**后端开发** · SpringBoot / MyBatis-Plus / Redis / Redisson / MySQL

**项目简介**: 基于 Spring Boot 的本地生活服务平台，实现商铺点评、优惠券秒杀、用户社交、内容推送等核心功能；通过深度整合 Redis，系统性解决高并发场景下的性能与一致性问题。

### Skill-First Hybrid RAG 智能问答系统
**AI 系统开发** · Python / FastAPI / LangChain / LlamaIndex / LangGraph

**项目简介**: 基于 FastAPI 与 LangGraph 构建的技能优先、混合检索智能问答系统，通过 Agent 动态路由与多检索器融合，提升复杂语义查询的可靠性与可解释性，实现可审计的本地化 Agent 工作台。

**主要内容**:
- **技能优先的 Agent 工作流设计**: 以 Markdown 文件（SKILL.md）定义可审计技能，利用 LangGraph 实现多步推理 Agent，依据用户意图自动规划任务、路由至匹配技能，并支持自我反思与回退，克服传统 RAG 固定链路的局限。
- **混合检索与结果融合**: 并行执行向量语义检索与 BM25 关键词检索，采用倒数秩融合（RRF）算法整合异构结果，兼顾字面精度与语义广度，在知识密集型场景中 MRR 提升 15-20% 且端到端问答性能提升 15-35%。
- **全链路可观测性**: 前端实时流式展示推理过程、工具调用链与证据来源；所有提示词、技能文件及索引以可见文件形式暴露，便于调试、审计与优化，满足高可靠性场景的透明性要求。
- **本地文件优先架构**: 摒弃 MySQL/Redis 等外部依赖，长期记忆、知识库与技能均以可版本管理的本地文件存储，降低部署复杂度，保障数据溯源与系统可维护性。

---

## 技术能力

- **Agent 应用开发**: 熟悉 RAG、Agent、Function Calling、MCP 等大模型主流开发范式，掌握基于 LangChain/LangGraph 框架的多智能体状态机编排与构建；深入理解 Agent 核心机制，熟悉 ReAct 思维链、工具调用、上下文管理及记忆系统的落地；熟练运用 Vibe-coding 提升工程迭代效能。

---

## 竞赛获奖

- [华为第三届大学生信息存储技术竞赛 · 挑战赛 **全国二等奖**](https://developer.huaweicloud.com/competition/information/1300000150/introduction)（SSD赛题第二名）, 2026 年 1 月
- [第二十二届中国研究生数学建模竞赛 **全国一等奖**](https://cpipc.acge.org.cn/cw/hp/4), 2025 年 11 月
- [第十五届中国大学生计算机设计大赛 **全国二等奖**](https://jsjds.blcu.edu.cn/info/1043/1741.htm), 2022 年 9 月