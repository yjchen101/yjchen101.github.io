# Waline 评论区配置

博客继续使用 GitHub Pages。Waline 服务和数据库单独部署，评论不写入博客仓库，也不需要重新构建博客才能显示。

已准备好的访客体验：免登录、昵称必填、邮箱选填、中文界面、跟随博客切换深浅色。不同文章使用各自的 URL 路径区分评论。

## 1. 部署 Waline

打开 [Waline 官方快速上手](https://waline.js.org/guide/get-started/)，点击页面中的 **Vercel** 部署按钮，使用 GitHub 账号登录 Vercel。

创建项目，例如 `yjc-blog-comments`。这是独立的评论服务项目；博客仓库继续部署到 GitHub Pages。

## 2. 创建数据库

按官方教程，在 Vercel 项目的 **Storage → Create Database** 中选择 **Neon**，选择适合个人博客的免费额度方案（以平台显示的当前条款为准），将数据库连接到项目。

点击 **Open in Neon → SQL Editor**，复制官方 [waline.pgsql](https://github.com/walinejs/waline/blob/main/assets/waline.pgsql) 的全部 SQL 并运行，创建评论所需的数据表。仅在这个新数据库中初始化一次。

回到 Vercel 的 **Deployments**，对最新部署点击 **Redeploy**，使数据库配置生效。

## 3. 注册管理员

打开 Vercel 提供的服务地址，例如 `https://yjc-blog-comments.vercel.app`，立即访问：

```text
https://你的评论服务域名/ui/register
```

第一个注册的账号会成为管理员。访客无需注册；这个账号只供博主管理评论。之后通过 `/ui` 登录后台。

## 4. 接入博客

在博客 `_config.yml` 中填入实际的服务地址（不带 `/ui`）：

```yaml
comments:
  provider: waline
  waline:
    server_url: "https://你的评论服务域名"
```

服务地址是公开信息，可以提供给协作者。数据库密码、连接串、Vercel Token 和管理员密码无需填写到博客配置中。

提交并推送博客改动后，原有 GitHub Pages 工作流会更新页面。文章底部会出现评论区，首页和标签页不会显示。服务地址留空时不会加载 Waline。

## 5. 验证

用浏览器无痕窗口打开一篇文章，填写昵称并留言，不填写邮箱、不登录，确认评论能够提交。再打开另一篇文章，确认评论分开显示。

如果评论无法加载，先确认评论服务地址在未登录 Vercel 的无痕窗口中也能访问；若跳转到 Vercel 登录页，检查项目的 Deployment Protection 设置。若读者主要在中国大陆，也应实际测试访问速度；必要时为评论服务配置可访问的自定义域名。

## 可选：评论审核

需要先审核再展示时，在 Vercel 项目环境变量中设置 `COMMENT_AUDIT=true` 并重新部署。同步将 `_includes/comments/waline.html` 中的输入框提示改为“评论提交后需审核才能显示”。

后台地址、免费额度和配置细节以 [Waline 官方文档](https://waline.js.org/) 为准。
