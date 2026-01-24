#!/bin/bash
echo "=== 模拟浏览器检查脚本 ==="
echo ""

echo "1. 检查 index.html 中的资源路径:"
if [ -f "public/index.html" ]; then
  echo "   CSS 文件:"
  grep -o 'href="[^"]*\.css"' public/index.html
  echo ""
  echo "   JS 文件:"
  grep -o 'src="[^"]*\.js"' public/index.html
  echo ""
  echo "   图片文件:"
  grep -o 'src="[^"]*\.\(png\|jpg\|jpeg\|gif\|svg\)"' public/index.html | head -5
fi

echo ""
echo "2. 测试资源可访问性:"
echo "   运行以下命令测试资源是否可访问:"
echo ""
echo "   测试 CSS:"
echo "   curl -I https://planarcat.github.io/blog/css/main.css"
echo ""
echo "   测试 JS:"
echo "   curl -I https://planarcat.github.io/blog/js/main.js"
echo ""
echo "   测试首页:"
echo "   curl -I https://planarcat.github.io/blog/"
echo ""
echo "3. 如果返回 404，可能是路径问题。"
echo "   需要检查 _config.yml 中的 url 和 root 设置:"
echo "   url: https://planarcat.github.io/blog"
echo "   root: /blog/"
echo ""
echo "4. 如果资源路径错误，可以临时修复:"
echo "   将 /blog/ 改为相对路径 ./ 或 /"
echo "   修改命令:"
echo "   sed -i '' 's|/blog/|./|g' public/index.html"
echo "   sed -i '' 's|/blog/|/|g' public/css/*.css 2>/dev/null || true"
