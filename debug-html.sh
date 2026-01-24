#!/bin/bash
echo "=== 调试生成的 HTML 文件 ==="
echo ""

# 检查 public 目录
if [ ! -d "public" ]; then
  echo "❌ public 目录不存在，需要先运行 hexo generate"
  exit 1
fi

echo "1. 检查文件结构:"
ls -la public/

echo ""
echo "2. 检查 index.html 是否存在:"
if [ -f "public/index.html" ]; then
  echo "✅ index.html 存在"
  echo "   文件大小: $(wc -c < public/index.html) 字节"
  echo "   行数: $(wc -l < public/index.html) 行"
else
  echo "❌ index.html 不存在"
  exit 1
fi

echo ""
echo "3. 检查 index.html 内容:"
echo "=== 前 20 行 ==="
head -20 public/index.html
echo ""
echo "=== 后 10 行 ==="
tail -10 public/index.html

echo ""
echo "4. 检查是否有内容标签:"
if grep -q "<body" public/index.html; then
  echo "✅ 找到 <body> 标签"
else
  echo "❌ 没有找到 <body> 标签，HTML 可能为空"
fi

if grep -q "<article" public/index.html || grep -q "post-content" public/index.html; then
  echo "✅ 找到文章内容"
else
  echo "⚠️  没有找到明显的文章内容"
fi

echo ""
echo "5. 检查资源文件:"
echo "   CSS 文件:"
find public -name "*.css" | head -5
echo "   JS 文件:"
find public -name "*.js" | head -5

echo ""
echo "6. 检查 Hexo 配置:"
if [ -f "_config.yml" ]; then
  echo "   主题配置:"
  grep "theme" _config.yml
  echo "   文章数量:"
  find source/_posts -name "*.md" 2>/dev/null | wc -l
fi
