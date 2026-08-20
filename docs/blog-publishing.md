# 分散文章发布

文章可以继续散落在不同项目和笔记目录中。博客仓库只保存一份发布快照，Jekyll 仍然从 `_posts/` 构建。

## 首次发布

源文件需要有标准的 Jekyll front matter：

```markdown
---
title: DeerFlow 架构解析
date: 2026-08-03 12:00:00 +0800
categories: [开源]
tags: [DeerFlow, Agent]
---

正文内容。
```

在博客仓库执行：

```bash
bundle exec ruby tools/publish_posts.rb publish \
  /Users/yjc/workspace/project-a/notes/deerflow.md \
  --id deerflow-architecture
```

`--id` 是文章的稳定标识，只能使用字母、数字、下划线和连字符。脚本会：

- 将源文件登记到 `.blog/sources.yml`；
- 生成 `_posts/YYYY-MM-DD-deerflow-architecture.md`；
- 为发布副本补充 `blog_id` 和固定 permalink（源文件不会被修改）。

当前 `source_root` 指向 Pi 项目根目录 `/Users/yjc/code/work/study/pi`。源文件应放在该目录内；如果以后改变目录布局，修改 `.blog/sources.yml` 中的 `source_root`。

## 文章模板

模板源文件位于 Pi 项目根目录：[pi-arch.md](https://github.com/earendil-works/pi/blob/main/pi-arch.md)。复制它开始写作。模板包含常用 front matter、正文结构和参考资料链接。

修改源文件后，在博客仓库执行 `bundle exec ruby tools/publish_posts.rb sync`，不要直接编辑 `_posts/` 快照。

## 更新文章

只修改原始 Markdown，然后运行：

```bash
bundle exec ruby tools/publish_posts.rb sync
git add .
git commit -m "docs: update blog posts"
git push
```

不要直接编辑 `_posts/`，它是发布快照。GitHub Actions 不会读取本机其他目录，因此同步后的 `_posts/` 必须提交到博客仓库。

## 检查是否同步

```bash
bundle exec ruby tools/publish_posts.rb check
```

脚本只同步 Markdown 正文，不处理图片。文章中的云存储图片 URL 会原样保留。

已有 `_posts/` 文章暂未纳入索引，可以继续正常使用；后续新文章按上述流程发布即可。
