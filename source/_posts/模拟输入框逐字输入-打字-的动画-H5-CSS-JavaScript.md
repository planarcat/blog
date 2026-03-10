---
title: 模拟输入框逐字输入(打字)的动画实现方案
date: 2026-03-02 11:28:07
tags:
    - 前端开发
    - 动画效果
    - Vue.js
    - CSS
    - JavaScript
categories:
    - 前端开发
---

前些天，在做一个项目时，需要实现一个模拟输入框逐字输入(打字)的动画效果。

## 核心需求分析

在开始实现之前，我首先明确了几个关键的技术需求：

1. **逐字输入效果**：文字需要逐个字符出现，每个字符之间有时间间隔，模拟真实打字的速度感
2. **光标控制**：光标需要保持在文字末尾，动画停止时停留在最后一个字符后面并闪烁，且支持多行换行
3. **交互限制**：动画过程中输入框不能手动输入文字，也不能将光标插入到其他位置
4. **状态保持**：动画结束后，同样需要保持只读状态，防止用户干扰

## 方案一：基于contenteditable的实现

最初我尝试使用`contenteditable`属性来实现逐字输入，配合Selection API来控制光标位置。这个方案看起来比较直接，因为`contenteditable`天生支持文本编辑功能。

### 实现代码

```html
<template>
    <div
        ref="editableDiv"
        contenteditable="true"
        class="text-1xl h-full w-full cursor-default overflow-hidden whitespace-pre-wrap border-none bg-transparent font-['Source_Han_Sans_CN'] font-normal text-[#18181d] outline-none"
        :class="{ 'placeholder-text': textareaValue === '' }"
        @keydown.prevent="handleKeyDown"
        @paste.prevent
    ></div>
</template>
```

```javascript
<script setup lang="ts">
import { ref, onMounted } from 'vue'

const textareaValue = ref('')
const editableDiv = ref<HTMLElement | null>(null)
// 定时器变量
const timers = {
    animationTimeout: null as NodeJS.Timeout | null,
    animationInterval: null as NodeJS.Timeout | null
}

/**
 * 开始文字输入动画
 */
const startTextAnimation = () => {
    // 设置2秒延迟
    timers.animationTimeout = setTimeout(() => {
        const targetText =
            '这是一段很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长的文字。'
        let currentIndex = 0

        // 清除现有内容
        textareaValue.value = ''
        if (editableDiv.value) {
            editableDiv.value.innerHTML = ''
        }

        // 设置逐字输入间隔
        timers.animationInterval = setInterval(() => {
            if (currentIndex < targetText.length) {
                textareaValue.value += targetText[currentIndex]
                if (editableDiv.value) {
                    editableDiv.value.innerHTML = textareaValue.value
                    moveCursorToEnd()
                }
                currentIndex++
            } else {
                // 清除定时器
                clearTimeout(timers.animationTimeout)
                clearInterval(timers.animationInterval)
            }
        }, 100) // 每100毫秒输入一个字符，速度更自然
    }, 2000) // 2秒延迟
}

/**
 * 移动光标到末尾
 */
const moveCursorToEnd = () => {
    const element = editableDiv.value
    if (!element) return

    // element.focus()
    const range = document.createRange()
    const selection = window.getSelection()
    range.selectNodeContents(element)
    range.collapse(false) // false表示折叠到范围的末尾
    selection?.removeAllRanges()
    selection?.addRange(range)
}

/**
 * 处理键盘事件
 */
const handleKeyDown = (e: KeyboardEvent) => {
    (e.target as HTMLElement).innerHTML = textareaValue.value
    // 光标移动到末尾
    moveCursorToEnd()
}

/**
 * 组件挂载时初始化
 */
onMounted(() => {
    // 重置动画状态
    textareaValue.value = ''
    if (editableDiv.value) {
        editableDiv.value.innerHTML = ''
    }

    startTextAnimation()
})

/**
 * 组件卸载时清除定时器
 */
onUnmounted(() => {
    clearTimeout(timers.animationTimeout)
    clearInterval(timers.animationInterval)
})
</script>
```

### 方案一的问题与局限性

经过实际测试，这个方案存在一些明显的问题：

1. **焦点管理问题**：输入框需要手动获取焦点，如果失去焦点，光标就会消失，影响用户体验
2. **输入法兼容性问题**：英文输入法时`@keydown.prevent`能正常阻止默认行为，但中文输入法下会失效，导致可以输入中文，而删除功能却正常工作，造成输入结果不一致
3. **光标控制复杂**：需要频繁调用Selection API来维护光标位置，代码复杂度较高

由于这些问题的存在，特别是中文输入法兼容性问题难以解决，我决定尝试第二个方案。

## 方案二：基于CSS伪元素的实现

经过重新思考，我决定采用更简洁的方案：使用`::after`伪元素来模拟光标，配合CSS动画实现闪烁效果。这个方案完全避免了输入法兼容性问题，实现更加优雅。

### 实现代码

```html
<template>
    <div
        ref="editableDiv"
        class="typewriter-box text-1xl h-full w-full cursor-default overflow-hidden whitespace-pre-wrap border-none bg-transparent font-['Source_Han_Sans_CN'] font-normal text-[#18181d] outline-none"
        :class="{
      'placeholder-text': state.textareaValue === '',
      'show-cursor': state.showCursor,
      inputing:
        state.textareaValue !==
        '这是一段很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长的文字。'
    }"
    ></div>
</template>
```

```javascript
<script setup lang="ts">
import { ref, onMounted } from 'vue'

const state = reactive({
    textareaValue: '',
    showCursor: false
})
const timers = {
    animationTimeout: null as NodeJS.Timeout | null,
    animationInterval: null as NodeJS.Timeout | null
}

const editableDiv = ref<HTMLElement | null>(null)

/**
 * 开始文字输入动画
 */
const startTextAnimation = () => {
    // 设置2秒延迟
    timers.animationTimeout = setTimeout(() => {
        // 显示光标
        state.showCursor = true

        const targetText =
            '这是一段很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长的文字。'
        let currentIndex = 0

        // 清除现有内容
        state.textareaValue = ''
        if (editableDiv.value) {
            editableDiv.value.innerHTML = ''
        }

        // 设置逐字输入间隔
        timers.animationInterval = setInterval(() => {
            if (currentIndex < targetText.length) {
                state.textareaValue += targetText[currentIndex]
                if (editableDiv.value) {
                    editableDiv.value.innerHTML = state.textareaValue
                }
                currentIndex++
            } else {
                // 清除定时器
                clearTimeout(timers.animationTimeout)
                clearInterval(timers.animationInterval)
            }
        }, 100) // 每100毫秒输入一个字符，速度更自然
    }, 2000) // 2秒延迟
}

/**
 * 组件挂载时初始化
 */
onMounted(() => {
    // 重置动画状态
    state.textareaValue = ''
    state.showCursor = false
    if (editableDiv.value) {
        editableDiv.value.innerHTML = ''
    }

    startTextAnimation()
})

/**
 * 组件卸载时清除定时器
 */
onUnmounted(() => {
    clearTimeout(timers.animationTimeout)
    clearInterval(timers.animationInterval)
})
</script>
```

```style
<style scoped>
.typewriter-box {
    position: relative;
    -webkit-user-select: none;
    -moz-user-select: none;
    -ms-user-select: none;
    user-select: none;
    pointer-events: none;
    min-height: 1.2em;
}

.typewriter-box::after {
    content: '';
    display: none;
    width: 2px;
    height: 1.2em;
    background-color: #18181d;
    vertical-align: middle;
    margin-left: 2px;
    position: relative;
    z-index: 1;
    animation: blink 1s step-end infinite;
}

.typewriter-box.show-cursor::after {
    display: inline-block;
}

/* 输入中不闪烁光标，保持光标常显 */
.typewriter-box.inputing::after {
    animation: none;
}

@keyframes blink {
    from,
    to {
        opacity: 1;
    }
    50% {
        opacity: 0;
    }
}
</style>
```

### 方案二的优势分析

与方案一相比，这个方案完美达成了需求，并具有以下一些优势：

1. **完全避免输入法兼容性问题**：通过`user-select: none`和`pointer-events: none`彻底禁用用户交互
2. **光标控制简单可靠**：CSS伪元素实现的光标无需复杂的JavaScript控制
3. **性能更好**：减少了DOM操作和Selection API调用
4. **代码更简洁**：逻辑清晰，维护成本低

### 关键实现要点

- **交互禁用**：通过CSS属性彻底阻止用户输入和选择
- **光标模拟**：使用`::after`伪元素配合CSS动画实现闪烁效果
- **状态管理**：通过Vue响应式状态控制动画流程
- **定时器管理**：确保组件卸载时正确清理定时器

## 总结与最佳实践

经过两个方案的对比实践，我总结出以下几点经验：

### 方案选择建议

1. **简单场景**：如果只需要基本的逐字输入效果，推荐使用方案二（CSS伪元素）
2. **复杂交互**：如果需要支持用户后续编辑，可以考虑优化方案一，但要注意输入法兼容性问题
3. **性能考虑**：方案二在性能上更优，适合移动端或性能敏感场景

### 技术实现要点

1. **定时器管理**：一定要在组件卸载时清理定时器，避免内存泄漏
2. **状态同步**：确保Vue响应式状态与DOM内容保持同步
3. **用户体验**：考虑添加暂停、继续、重置等控制功能
4. **可访问性**：为屏幕阅读器添加适当的ARIA属性

### 扩展思路

- 可以添加打字速度调节功能
- 支持多种光标样式（如方块光标、下划线光标等）
- 实现打字机声音效果
- 添加文本高亮动画

## 问题遗留
contenteditable方案中，在禁止输入默认行为后，英文输入法下正常无法输入，但是中文输入法下依然可以输入，这个问题最终没有找到原因与解决方法。