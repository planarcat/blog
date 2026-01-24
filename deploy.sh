#!/bin/bash
# 清空并生成静态文件
hexo clean
hexo generate

# 进入 public 文件夹（生成的静态文件）
cd public

# 初始化 Git 并强制推送到主仓库的 blog 分支
git init
git add .
git commit -m "博客更新: $(date +'%Y-%m-%d %H:%M:%S')"

# 强制推送到 planarcat.github.io 仓库的 blog 分支
git push -f https://github.com/planarcat/blog.git HEAD:blog

# 回到项目根目录
cd ..
