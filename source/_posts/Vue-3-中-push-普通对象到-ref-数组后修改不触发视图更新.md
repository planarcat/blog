---
title: Vue 3 中 push 普通对象到 ref 数组后修改不触发视图更新
date: 2026-05-05 21:54:28
tags:
---
# Vue 3 中 push 普通对象到 `ref` 数组后修改不触发视图更新

> 一次 SSE 流式渲染 bug 的排查与修复笔记

## 一、问题

我在做一个基于 Vue 3 的 AI 对话交互界面，后端通过 SSE 将 LLM 的一系列回复一段段推送到前端，我期望 AI 对话的内容随 SSE 推送实时渲染，而非等到所有回复全部推送完毕再一次性渲染。但实际情况是：

1. 点发送后，屏幕上只看到自己刚发的那条消息，AI 回复始终空白；
2. 直到第二次点发送，上一次的 AI 回复内容才会和这一次的用户消息一起冒出来。

打日志确认 SSE 回调里的数据是正常到达的，也就是说**数据收到了，但视图没在收到时刷新**，要等下一次发送时才"顺路"渲染出来。

## 二、原代码

页面 `pages/index/index.vue` 中，发送逻辑大致是这样写的：

```ts
const dialogueList = ref<{
  event: string;
  text: string;
}[]>([]);

async function onSend() {
  const newMessage = sendMessage.value;
  dialogueList.value.push({
    event: 'user',
    text: newMessage,
  });

  // 准备一个空对象 push 进去占位
  const newDialogue = {
    event: '',
    text: '',
  };
  dialogueList.value.push(newDialogue);

  // 然后在 SSE 回调里持续往这个对象上写内容
  chat({
    sendMessage: newMessage,
    getStream: ({ eventType, status, result }) => {
      newDialogue.event = eventType;
      if (eventType === 'status') {
        newDialogue.text = status;
      } else if (eventType === 'echo' && typeof result === 'string') {
        newDialogue.text = result;
      }
    },
  });
}
```

直觉很自然：先放个空气泡占位，拿到这个对象的引用，之后随 SSE 事件不断改它的字段就行了。但这个写法恰好踩中了 Vue 3 响应式系统的一个常见陷阱。

## 三、问题原因

**push 进去的对象，跟数组里被追踪的对象，不是同一个对象。**

Vue 3 的 `ref` 在内部对数组使用 `reactive` 包装。当向一个 reactive 数组 push 一个**普通对象**时，Vue 会用 Proxy 把这个普通对象再包装一层，存进数组里。也就是说：

- 数组里**真正存放并被 Vue 追踪**的，是一个 `Proxy(原对象)`；
- 而局部变量 `newDialogue` 仍然指向**原始对象**——它根本没被 Proxy 包装过。

```text
            ┌───────────────────────────────┐
            │ dialogueList.value (Proxy)    │
            └─────────────┬─────────────────┘
                          │
                          ▼
            ┌───────────────────────────────┐
            │ [Proxy(item0), Proxy(item1)]  │  ← Vue 追踪这些
            └───────────────────────────────┘
                              │
                              ▼  解开代理后指向的是
            ┌───────────────────────────────┐
            │ 原始 newDialogue 对象         │  ← 局部变量指向这里
            └───────────────────────────────┘
```

之后 `newDialogue.text = status` 直接操作**原始对象**，**绕开了 Proxy**，自然不会触发 Vue 的依赖通知，视图也就不会重新渲染。

那为什么第二次发送时旧内容会"突然出现"？因为下一次 `onSend` 又调用了 `dialogueList.value.push(...)`，这一次操作经过的是数组的 Proxy，触发了对 `dialogueList` 的依赖更新，整个列表重新渲染——此时再读取数组里那个被代理的对象时，它身上的 `text` 字段早已被改过，于是**这一帧才把上一轮的 AI 回复一起渲染出来**。

> 一句话：**写在原对象上的修改没人通知 Vue；下一次别的写入触发了通知，旧修改才被"顺路"渲染。**

## 四、修复方案

只需要把"持续修改的目标"换成数组里那个**已被代理**的对象。最简单的写法是：先 push，再用下标把代理对象取回来：

```ts
async function onSend() {
  const newMessage = sendMessage.value.trim();
  if (!newMessage) return;
  sendMessage.value = '';

  dialogueList.value.push({
    event: 'user',
    text: newMessage,
  });
  dialogueList.value.push({
    event: '',
    text: '',
  });

  // 关键：从数组里取出代理后的对象，对它的赋值才会被 Vue 追踪
  const newDialogue = dialogueList.value[dialogueList.value.length - 1];

  chat({
    sendMessage: newMessage,
    getStream: ({ eventType, status, result }) => {
      newDialogue.event = eventType;
      if (eventType === 'status') {
        newDialogue.text = status;
      } else if (eventType === 'echo' && typeof result === 'string') {
        newDialogue.text = result;
      }
    },
  });
}
```

改完之后，AI 气泡随 SSE 事件**逐帧**刷新，不需要等下一次发送。

下面三种写法等价，按需选择：

```ts
// 写法 A：push 之后通过下标取回（改动最小，本次采用）
dialogueList.value.push({ event: '', text: '' });
const newDialogue = dialogueList.value[dialogueList.value.length - 1];

// 写法 B：push 的返回值是新长度，可以一行拿到 index
const idx = dialogueList.value.push({ event: '', text: '' }) - 1;
const newDialogue = dialogueList.value[idx];

// 写法 C：先用 reactive 包装，再 push
import { reactive } from 'vue';
const newDialogue = reactive({ event: '', text: '' });
dialogueList.value.push(newDialogue);  // reactive 是幂等的，不会被重复包装
```

## 五、总结

这个坑的本质可以提炼成一条规则：

> 在 Vue 3 里，如果打算"持有一个引用，后续持续修改它来驱动视图"——这个引用必须来自响应式系统（`ref.value[i]`、`reactive(obj)` 等），而不是 push 进去的那个原始字面量。

容易再次踩坑的几个场景，记下来提醒自己：

1. **流式渲染 / SSE / WebSocket**：每一帧回调都改同一个对象的字段；
2. **乐观更新**：先 push 占位项，再等接口返回回填；
3. **拖拽 / 编辑器**：拿着一个"当前选中项"的局部变量到处改属性。

只要意识到 "**push 进去的对象 ≠ 数组里被追踪的对象**"，这类 bug 基本不会再出现。
