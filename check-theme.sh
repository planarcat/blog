#!/bin/bash
echo "=== 检查主题配置 ==="
echo ""

echo "1. 检查主题目录:"
if [ -d "themes/next" ]; then
  echo "✅ Next 主题目录存在"
  echo "   文件数量: $(find themes/next -type f | wc -l)"
  echo "   配置文件:"
  if [ -f "themes/next/_config.yml" ]; then
    echo "   ✅ themes/next/_config.yml 存在"
    echo "      文件大小: $(wc -l < themes/next/_config.yml) 行"
  else
    echo "   ❌ themes/next/_config.yml 不存在"
    echo "      尝试从示例文件复制: cp themes/next/_config.yml themes/next/_config.example.yml"
  fi
else
  echo "❌ Next 主题目录不存在"
  echo "   运行: git clone https://github.com/next-theme/hexo-theme-next themes/next"
fi

echo ""
echo "2. 检查 Hexo 配置文件中的主题设置:"
if [ -f "_config.yml" ]; then
  theme_setting=$(grep "^theme:" _config.yml)
  echo "   主题设置: $theme_setting"
  if [[ "$theme_setting" == *"next"* ]]; then
    echo "   ✅ 主题设置为 next"
  else
    echo "   ❌ 主题不是 next，请修改为: theme: next"
  fi
fi

echo ""
echo "3. 检查是否有文章:"
if [ -d "source/_posts" ]; then
  post_count=$(find source/_posts -name "*.md" 2>/dev/null | wc -l)
  echo "   文章数量: $post_count"
  if [ $post_count -eq 0 ]; then
    echo "   ⚠️  没有文章，创建第一篇: hexo new \"我的第一篇博客\""
  else
    echo "   文章列表:"
    ls -la source/_posts/
  fi
else
  echo "   ❌ source/_posts 目录不存在"
  mkdir -p source/_posts
fi

echo ""
echo "4. 测试本地构建:"
echo "   运行以下命令测试:"
echo "   hexo clean"
echo "   hexo generate"
echo "   然后检查 public/index.html 是否有内容"
