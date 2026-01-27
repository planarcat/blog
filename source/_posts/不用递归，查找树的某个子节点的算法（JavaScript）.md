---
title: 不用递归，查找树的某个子节点的算法（JavaScript）
date: 2026-01-27 15:03:50
tags: [JavaScript, 树, 查找算法]
---

在 JavaScript 中，我们可以使用栈（深度优先）或队列（广度优先）来非递归地遍历树形结构。以下是几种实现方式：

## 1. 深度优先搜索（使用栈）

```javascript
class TreeNode {
    constructor(id, data = null) {
        this.id = id;
        this.data = data;
        this.children = [];
    }
}

// 深度优先搜索（非递归）
function findNodeByIdDFS(root, targetId) {
    if (!root) return null;

    const stack = [root];

    while (stack.length > 0) {
        const node = stack.pop();

        // 检查当前节点
        if (node.id === targetId) {
            return node;
        }

        // 将子节点压入栈（注意顺序，如果想要与递归顺序一致，需要反转children）
        // 这里反转是为了先遍历第一个子节点
        const children = node.children.slice().reverse();
        for (const child of children) {
            stack.push(child);
        }
    }

    return null;
}
```

## 2. 广度优先搜索（使用队列）

```javascript
// 广度优先搜索（非递归）
function findNodeByIdBFS(root, targetId) {
    if (!root) return null;

    const queue = [root];

    while (queue.length > 0) {
        const node = queue.shift();

        // 检查当前节点
        if (node.id === targetId) {
            return node;
        }

        // 将子节点加入队列
        for (const child of node.children) {
            queue.push(child);
        }
    }

    return null;
}
```

## 3. 完整示例

```javascript
// 构建示例树
const root = new TreeNode(1);
const node2 = new TreeNode(2);
const node3 = new TreeNode(3);
const node4 = new TreeNode(4);
const node5 = new TreeNode(5);
const node6 = new TreeNode(6);

root.children = [node2, node3];
node2.children = [node4, node5];
node3.children = [node6];

// 测试DFS
console.log('DFS - 查找节点 4:', findNodeByIdDFS(root, 4)?.id); // 4
console.log('DFS - 查找节点 7:', findNodeByIdDFS(root, 7)?.id); // undefined

// 测试BFS
console.log('BFS - 查找节点 6:', findNodeByIdBFS(root, 6)?.id); // 6
console.log('BFS - 查找节点 8:', findNodeByIdBFS(root, 8)?.id); // undefined
```

## 4. 更通用的实现（支持自定义匹配条件）

```javascript
// 通用的树节点查找函数
function findTreeNode(root, predicate, strategy = 'dfs') {
    if (!root) return null;

    if (strategy === 'dfs') {
        // 深度优先
        const stack = [root];

        while (stack.length > 0) {
            const node = stack.pop();

            if (predicate(node)) {
                return node;
            }

            // 将子节点加入栈
            const children = node.children.slice().reverse();
            for (const child of children) {
                stack.push(child);
            }
        }
    } else {
        // 广度优先
        const queue = [root];

        while (queue.length > 0) {
            const node = queue.shift();

            if (predicate(node)) {
                return node;
            }

            // 将子节点加入队列
            for (const child of node.children) {
                queue.push(child);
            }
        }
    }

    return null;
}

// 使用示例
const result1 = findTreeNode(root, node => node.id === 5, 'dfs');
const result2 = findTreeNode(root, node => node.data?.name === 'someName', 'bfs');
```

## 5. 使用生成器实现迭代遍历

```javascript
// 使用生成器遍历树（深度优先）
function* traverseTreeDFS(node) {
    const stack = [node];

    while (stack.length > 0) {
        const currentNode = stack.pop();
        yield currentNode;

        const children = currentNode.children.slice().reverse();
        for (const child of children) {
            stack.push(child);
        }
    }
}

// 使用生成器查找节点
function findNodeWithGenerator(root, targetId) {
    for (const node of traverseTreeDFS(root)) {
        if (node.id === targetId) {
            return node;
        }
    }
    return null;
}
```

## 6. 性能考虑

- 深度优先（DFS）：使用栈，空间复杂度为 O(h)，其中 h 是树的高度
- 广度优先（BFS）：使用队列，空间复杂度为 O(w)，其中 w 是树的宽度

选择哪种方法取决于：
1. 如果目标节点可能在树的深层，DFS 可能更快
2. 如果目标节点可能在浅层，BFS 可能更快
3. 如果树非常宽（子节点很多），DFS 更节省内存
4. 如果树非常深，BFS 可能更合适（但要注意队列大小）
5. 这些实现都避免了递归，适合处理深度很大的树形结构，不会出现栈溢出的问题。
