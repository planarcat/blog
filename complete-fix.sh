#!/bin/bash
echo "=== 完整修复脚本 ==="
echo ""

# 1. 检查当前状态
echo "1. 检查当前状态:"
ls -la pnpm-lock.yaml 2>/dev/null || echo "pnpm-lock.yaml 不存在"

echo ""
echo "2. 备份现有配置:"
if [ -f ".github/workflows/deploy.yml" ]; then
  cp .github/workflows/deploy.yml .github/workflows/deploy.yml.backup
  echo "已备份 deploy.yml"
fi

echo ""
echo "3. 创建新的工作流配置:"
mkdir -p .github/workflows
cat > .github/workflows/deploy.yml << 'CONFIG'
name: Deploy Blog

on:
  push:
    branches: [main]

permissions:
  contents: read
  pages: write
  id-token: write

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    
    # 最简单的 pnpm 安装方式
    - name: Install pnpm
      run: npm install -g pnpm@8
    
    - name: Setup Node.js
      uses: actions/setup-node@v4
      with:
        node-version: '20'
    
    - name: Verify environment
      run: |
        echo "Node.js: $(node --version)"
        echo "pnpm: $(pnpm --version)"
        echo "当前目录: $(pwd)"
        echo "文件列表:"
        ls -la
    
    - name: Install dependencies
      run: |
        echo "安装依赖..."
        # 先检查 lock 文件
        if [ -f "pnpm-lock.yaml" ]; then
          echo "使用 pnpm-lock.yaml"
          # 尝试使用 --frozen-lockfile，如果失败则使用普通安装
          pnpm install --frozen-lockfile || pnpm install
        else
          echo "没有 lock 文件，重新生成"
          pnpm install
        fi
    
    - name: Install Hexo CLI
      run: pnpm add -g hexo-cli
    
    - name: Setup theme
      run: |
        if [ ! -d "themes/next" ]; then
          git clone https://github.com/next-theme/hexo-theme-next themes/next
        fi
    
    - name: Build blog
      run: |
        hexo clean
        hexo generate
        
        # 验证构建
        if [ ! -d "public" ]; then
          echo "构建失败，public 目录不存在"
          exit 1
        fi
        echo "构建成功，生成 $(find public -type f | wc -l) 个文件"
    
    - uses: actions/upload-pages-artifact@v3
      with:
        path: './public'

  deploy:
    environment:
      name: github-pages
      url: \${{ steps.deployment.outputs.page_url }}
    runs-on: ubuntu-latest
    needs: build
    steps:
    - name: Deploy to GitHub Pages
      id: deployment
      uses: actions/deploy-pages@v4
CONFIG

echo "✅ 配置已创建"

echo ""
echo "4. 本地测试构建:"
echo "   请在本地运行以下命令:"
echo "   rm -rf node_modules public"
echo "   pnpm install"
echo "   hexo clean && hexo generate"
echo "   如果成功，则提交并推送"

echo ""
echo "5. 执行命令:"
echo "   git add ."
echo "   git commit -m 'fix: 更新部署配置，修复pnpm问题'"
echo "   git push origin main"
