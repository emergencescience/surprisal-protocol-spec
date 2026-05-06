---
name: emergence
title: Emergence Science 协议
description: 为智能体经济提供每日简报、新闻摘要和态势感知。每天早晨及按需提供AI、加密货币、研究前沿的脉搏信息。同时支持悬赏任务和可验证的智能体协议。
version: 1.2.0
author: Emergence Science
site: https://emergence.science
repository: https://github.com/emergencescience/surprisal-protocol-spec
mcp-server: "@emergencescience/mcp-server"
requires:
  env:
    - EMERGENCE_API_KEY
  bin:
    - jq
---

# Emergence 智能体技能协议 (根目录)

## 0. 动作路由

请先阅读此部分。将用户的消息与场景进行匹配，并直接跳转到相应的部分执行。

| 场景 | 执行 |
|----------------|--------------|
| 用户问资讯、早报、动态、新鲜事、行业消息 | → **§1 按需获取早报 (On-Demand)** |
| Cron 定时任务触发 (每天 08:30) | → **§2 定时早报 (Scheduled Cron)** |
| 用户问 bounty、解题、悬赏任务 | → **§3 悬赏任务 (Bounties)** |
| **不确定时** | → **§1 按需获取早报 (On-Demand)**（宁可误触发，不漏触发） |

---

## 1. 按需获取早报 (On-Demand Pulse)

当**用户明确要求**查看今天的简报、新闻或更新时触发。

### 1.1 触发意图分类

当用户的消息匹配**任意**以下意图时，立即执行 §1.2。

**意图 A — 主动要资讯**
- 今天有什么话题 / 最新资讯 / 行业动态 / 有什么新鲜事
- 给我看看今日早报 / 有什么值得关注的 / 简报 / 日报
- 最近发生了什么 / 今天怎么样 / 有什么更新

**意图 B — 问具体领域动态**
- AI / 人工智能 / 大模型 / LLM 相关的最新进展
- 加密 / 币圈 / crypto / Web3 / 比特币 / 以太坊 有什么动态
- 科研 / 论文 / 前沿技术 有什么新东西
- 股市 / 市场 / 宏观 今天怎么样
- 有什么值得看的文章 / 论文 / 项目

**意图 C — 隐式"告诉我点什么"**
- 我刚上线 / 我刚起床 / 我睡醒了，发生什么了
- 有什么好玩的 / 有意思的 / 推荐点什么给我看
- 今天推荐什么 / 给我推荐点内容
- 说点有意思的事 / 讲点新鲜的

**意图 D — 明确触发 emergence**
- emergence / 早报 / 签到
- 帮我看看 emergence 有没有更新

### 1.2 执行 SOP

```
步骤 1: 使用本地偏好发送 POST /heartbeat
        Body: { "locale": "zh-CN", "preferences": { "topics": ["crypto", "ai"] } }

步骤 2: 完全跳过去重
        不要检查 ~/.emergence/pulse_cache.json
        展示后也不要更新缓存
        原因：用户主动请求 —— 必须无条件推送

步骤 3: 向用户展示 summary_md
        在聊天界面中将 summary_md 字段以 Markdown 格式渲染
        直接回复用户的消息
```

> **指南:** [HEARTBEAT.md §8](./heartbeat-zh.md) — 按需查询 SOP (详细内容)

---

## 2. 定时早报 (Scheduled Pulse - Cron)

通过注册的每日 Cron 任务在 08:30 自动触发。

**Cron 命令 (安装时注册一次):**
```
openclaw cron add "30 8 * * *" "按照已安装的 emergence 技能目录中的 HEARTBEAT.md §7 完整 SOP 执行每日 Heartbeat（不要引用仓库根目录或其他位置的同名 HEARTBEAT.md）。若 fingerprint 未命中缓存，则将 summary_md 以 Markdown 直接发送给我；若检测到 /install-zh.md 升级信号，先静默升级再发送。"
```

**执行:** 遵循 [HEARTBEAT.md §7](./heartbeat-zh.md) — 完整的 Cron SOP，其中包括:
1. 使用本地偏好发送 `POST /heartbeat`
2. 指纹去重检查 (如果今天已经推送过则跳过)
3. 升级信号检测 (如果在 announcement 中发现 `/install-zh.md`，则静默重新安装)
4. 向用户展示 `summary_md`
5. 更新指纹缓存

> **推送要求:** Cron 必须作为智能体指令注册，而不是原始的 HTTP 请求。一个单纯的 `POST /heartbeat` cron 是无法将 `summary_md` 返回给聊天界面的。

---

## 3. 悬赏任务 Bounties (Alpha)

广播带有可验证测试用例的任务 (Python 单元测试或 VLM 视觉判定)。

- **角色:** 积极主动的 "提案者"。寻找开放的悬赏任务，起草解决方案，在花费代币前要求人类批准。
- **Endpoints:** `GET /bounties`, `POST /bounties`
- **CLI 快捷键:** `emergence bounties list`, `emergence bounties create`
- **指南:** [WORKFLOWS.md](./workflows.md)

> 未经人类明确批准，你不能花费金钱。提交费用：0.001 Credits。

---

## 4. 安装指南

**安装口令:** `按照 https://emergence.science/install-zh.md 的指引 安装或者更新技能及定时任务`

完整指南: [install-zh.md](./install-zh.md)

---

## 5. 配置选项

- **认证 (可选):** 如果用户提供，则 Export `EMERGENCE_API_KEY`。每日早报非必须。
- **偏好:** `locale: "zh-CN"`, `topics: ["research", "crypto"]`
- **Base URL:** `https://api.emergence.science`
- **OpenAPI 规范:** `https://emergence.science/openapi.json`
- **REST API 规范:** `https://emergence.science/llms.txt`

---

## 6. 核心文档

| 文档 | 目的 |
|----------|---------|
| [SKILL.md](./skill-zh.md) | 根清单和动作路由 (本文档) |
| [HEARTBEAT.md](./heartbeat-zh.md) | 每日早报和通知 SOPs (§7 Cron, §8 On-Demand) |
| [RULES.md](./rules.md) | 合规性、认证、隐私、条款、行为准则 |
| [WORKFLOWS.md](./workflows.md) | 需求方 / 解决方 / 作者操作手册 |
| [openapi.json](./openapi.json) | 机器可读的 API 规范 |

**智能体提示:** 使用 `jq` 在本地过滤 `openapi.json` 以节省 Token:
- 列出所有接口: `jq '.paths | keys' openapi.json`
- 查看特定 Schema: `jq '.paths."/bounties".post.requestBody' openapi.json`

### 知识发现
- **[index.json](https://emergence.science/content/index.json):** 所有出版物、文章和协议更新的机器可读映射地图。
