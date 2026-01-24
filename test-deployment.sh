#!/bin/bash
echo "=== 部署测试脚本 ==="
echo ""

# 构建博客
echo "1. 构建博客..."
hexo clean
hexo generate

echo "2. 检查生成的 HTML 文件..."
if [ -f "public/index.html" ]; then
  echo "✅ index.html 存在"
  echo "   文件内容预览:"
  
  # 检查关键部分
  echo "   === 头部 ==="
  head -20 public/index.html
  
  echo ""
  echo "   === 检查 body 内容 ==="
  if grep -q "<article" public/index.html || grep -q "post-content" public/index.html; then
    echo "   ✅ 找到文章内容"
    # 提取文章内容预览
    grep -A5 -B5 "post-content" public/index.html | head -20 || true
  else
    echo "   ❌ 未找到文章内容标签"
    echo "   尝试查找其他内容:"
    grep -n "欢迎\|测试\|文章" public/index.html | head -10 || echo "未找到相关文本"
  fi
else
  echo "❌ index.html 不存在"
fi

echo ""
echo "3. 本地测试访问..."
echo "   在 public 目录启动本地服务器:"
echo "   cd public"
echo "   python3 -m http.server 8000"
echo "   然后访问: http://localhost:8000"
echo "   注意: 资源路径是 /blog/，本地可能无法正确加载"
echo "   可以临时修改路径测试:"
echo "   sed -i '' 's|/blog/|/|g' public/index.html"

echo ""
echo "4. GitHub Pages 状态检查:"
echo "   访问: https://github.com/planarcat/blog/deployments"
echo "   查看最近的部署状态"

echo ""
echo "5. 清除缓存访问:"
echo "   使用无痕窗口访问: https://planarcat.github.io/blog"
echo "   或添加随机参数: https://planarcat.github.io/blog?t=$(date +%s)"
