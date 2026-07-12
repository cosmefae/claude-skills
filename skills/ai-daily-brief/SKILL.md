---
name: ai-daily-brief
description: Generates a daily brief of the top AI-world news, deduped across a curated source list, with structured themed output.
Provenance: adapted from a private workspace skill — [cosmefae](https://hellofae.com)
---

Every morning, generate a daily brief of the top AI-world news.

## Authorized sources

Group 1 — Official blogs (highest priority):
- anthropic.com/news
- openai.com/blog
- deepmind.google/discover/blog

Group 2 — Business and market:
- bloomberg.com/technology
- techcrunch.com/category/artificial-intelligence
- venturebeat.com/ai

Group 3 — Product and consumer:
- huggingface.co/blog
- deeplearning.ai/the-batch

Group 4 — Regional sources (use only if they bring an exclusive angle not covered above):
- scmp.com
- asia.nikkei.com
- 36kr.com/en

This source list is a sensible default — edit it freely to match your own priorities (add/remove outlets, add a group for a specific region or beat).

## Mandatory search rule

Run EXACTLY 8 searches in parallel — 2 per group (broad + specific):

**Search 1a** — Group 1 (broad):
```
query: "AI 2026"
allowed_domains: ["anthropic.com", "openai.com", "deepmind.google"]
```
**Search 1b** — Group 1 (specific):
```
query: "AI announcement release news"
allowed_domains: ["anthropic.com", "openai.com", "deepmind.google"]
```

**Search 2a** — Group 2 (broad):
```
query: "AI 2026"
allowed_domains: ["bloomberg.com", "techcrunch.com", "venturebeat.com"]
```
**Search 2b** — Group 2 (specific):
```
query: "artificial intelligence business funding"
allowed_domains: ["bloomberg.com", "techcrunch.com", "venturebeat.com"]
```

**Search 3a** — Group 3 (broad):
```
query: "AI 2026"
allowed_domains: ["huggingface.co", "deeplearning.ai"]
```
**Search 3b** — Group 3 (specific):
```
query: "AI open source model"
allowed_domains: ["huggingface.co", "deeplearning.ai"]
```

**Search 4a** — Group 4 (broad):
```
query: "AI 2026"
allowed_domains: ["scmp.com", "asia.nikkei.com", "36kr.com"]
```
**Search 4b** — Group 4 (specific):
```
query: "AI China Asia technology"
allowed_domains: ["scmp.com", "asia.nikkei.com", "36kr.com"]
```

Deduplicate results before assembling the brief. If a source is unreachable, skip it silently.

## Time window

Include news from the **last 36 hours**. Don't use timezone as an exclusion criterion — treat UTC and local time as equivalent. If a story from the last 36h is still developing, include it tagged "📌 Developing". Don't re-present a story older than 36h as new.

## Relevance criterion

Include any news that someone following the AI ecosystem would consider important to know that day — whether a launch, a regulation, a notable statement, a paper, a market move, a partnership, an incident, or an emerging trend. The core test is: **does this change something or signal something about the state of AI?**

Exclude only:
- Duplicate of news already covered in the same 36h window
- Opinion or analysis with no new fact (a "what I think about AI" piece with no concrete news)
- Content about past events with no new development

## Volume

Include **8 to 15 news items minimum/maximum** per edition. Cover at least 3 distinct source groups.

## Mandatory brief structure

## 🧠 AI Daily Brief — [date]

**• TL;DR:** [3-4 bullets with the most important highlights]

---

Organize news into thematic sections. Use only sections that have relevant news. Mandatory emoji mapping per section:

- 🤖 Models & Releases
- 🏗️ Infrastructure & Partnerships
- 📈 Market & Business
- 🌏 Geopolitics & Global Race
- 🌍 International Expansion
- 🔓 Open Source
- 🔐 Security
- 📦 Products
- ⚖️ Regulation

Section header format: `### [emoji] [Section Name]`

Each news item: bold title, 2-4 direct lines — what happened and why it matters.

End with "Sources:" listing only the URLs actually used.

Write in English by default. Direct and concise. If invoked in a non-English workspace, match that language instead.

## Delivery

If invoked with a specific delivery target (e.g. a Slack channel, an email address, or another messaging integration), post the brief there — split into multiple sequential messages if it exceeds that channel's length limit. If invoked with no delivery target specified, deliver the brief as direct chat output.
