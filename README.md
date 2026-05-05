# planarcat 博客

基于 [Hexo](https://hexo.io/) 的静态博客站点，使用 [Butterfly](https://github.com/jerryc127/hexo-theme-butterfly) 主题，部署在 [GitHub Pages](https://pages.github.com/)。

线上地址：<https://planarcat.github.io/blog/>

## 环境要求

- [Node.js](https://nodejs.org/) 20.x（与 CI 一致）
- 包管理：本地可用 **pnpm**（推荐，与 GitHub Actions 一致）或 **npm**

## 快速开始

```bash
# 克隆（若主题以子模块形式存在，需带上子模块）
git clone --recurse-submodules <仓库地址>
cd blog

# 安装依赖（任选其一）
pnpm install
# 或
npm install
```

## 常用命令

| 命令 | 说明 |
|------|------|
| `pnpm build` / `npm run build` | 生成静态文件到 `public/`（`hexo generate`） |
| `pnpm clean` / `npm run clean` | 清理缓存与 `public`（`hexo clean`） |
| `pnpm server` / `npm run server` | 启动本地预览（当前脚本绑定 `192.168.50.248:4000`） |
| `pnpm deploy` / `npm run deploy` | 若配置了 Hexo 部署器则一键部署（本项目主要由 CI 发布） |

仅在本机任意地址访问预览时，可直接执行：

```bash
npx hexo server
```

默认一般为 `http://localhost:4000`。

## 写作

在 `source/_posts/` 下新建 Markdown 文章，或使用：

```bash
npx hexo new "文章标题"
```

站点与写作相关配置见根目录 `_config.yml`；主题配置见 `themes/butterfly/_config.yml`。

## 部署

向 **`main`** 分支推送代码后，由 [`.github/workflows/deploy.yml`](.github/workflows/deploy.yml) 自动：

1. 检出代码（含子模块）
2. 使用 Node 20 与 pnpm 安装依赖并执行 `hexo clean`、`hexo generate`
3. 将 `public/` 作为产物发布到 GitHub Pages

仓库需在 GitHub 中启用 Pages，并选择 **GitHub Actions** 作为来源。

## 项目结构（简要）

- `_config.yml` — Hexo 站点配置（语言 `zh-CN`、站点根路径 `/blog/` 等）
- `source/` — 文章与页面源码
- `themes/butterfly/` — Butterfly 主题
- `public/` — 构建输出（勿手改，由生成命令产生）

## 许可与致谢

- [Hexo](https://hexo.io/)
- [hexo-theme-butterfly](https://github.com/jerryc127/hexo-theme-butterfly)
