---
title: Vue中provide(依赖)和inject(注入)的使用
date: 2026-02-13 17:35:24
tags:
---

Vue 中的 provide 和 inject 是一对用于跨层级组件通信的 API，主要用于父组件向深层嵌套的子组件传递数据，避免了通过 props 逐层传递的繁琐。

## 基本使用

### 1. 父组件提供数据 (provide)

```vue
<script setup>
import { provide, ref, reactive } from 'vue'

// 提供静态数据
provide('message', 'Hello from parent')

// 提供响应式数据
const count = ref(0)
provide('count', count)

// 提供对象
const userInfo = reactive({
  name: 'John',
  age: 25
})
provide('userInfo', userInfo)

// 提供方法
const updateCount = (newValue) => {
  count.value = newValue
}
provide('updateCount', updateCount)
</script>
```

### 2. 子组件注入数据 (inject)

```vue
<script setup>
import { inject } from 'vue'

// 注入数据
const message = inject('message')
const count = inject('count')
const userInfo = inject('userInfo')
const updateCount = inject('updateCount')

// 使用默认值（如果父组件未提供）
const theme = inject('theme', 'light') // 默认值为 'light'

// 注入为只读（推荐）
const readonlyCount = inject('count', undefined, true)

// 调用父组件提供的方法
const handleClick = () => {
  updateCount(count.value + 1)
}
</script>

<template>
  <div>
    <p>{{ message }}</p>
    <p>Count: {{ count }}</p>
    <button @click="handleClick">增加</button>
  </div>
</template>
```

## 详细示例

### 场景：主题切换

#### ThemeProvider.vue (顶层组件)

```vue
<script setup>
import { provide, ref, computed } from 'vue'

const theme = ref('light')
const isDark = computed(() => theme.value === 'dark')

const toggleTheme = () => {
  theme.value = theme.value === 'light' ? 'dark' : 'light'
}

// 提供主题相关数据和函数
provide('theme', {
  theme,
  isDark,
  toggleTheme
})
</script>

<template>
  <div :class="theme">
    <slot />
  </div>
</template>
```

#### DeepChild.vue (深层嵌套组件)

```vue
<script setup>
import { inject } from 'vue'

// 注入主题配置
const themeConfig = inject('theme')

if (!themeConfig) {
  throw new Error('必须在 ThemeProvider 中使用')
}
</script>

<template>
  <button @click="themeConfig.toggleTheme">
    切换主题 (当前: {{ themeConfig.theme }})
  </button>
</template>
```

### 场景：国际化 (i18n)

#### I18nProvider.vue (顶层组件)

```vue
<script setup>
import { provide, ref, computed } from 'vue'

// 语言包
const messages = {
  en: {
    hello: 'Hello',
    welcome: 'Welcome to our application'
  },
  zh: {
    hello: '你好',
    welcome: '欢迎使用我们的应用'
  }
}

const locale = ref('zh')

const t = (key) => {
  return messages[locale.value][key] || key
}

const changeLocale = (newLocale) => {
  locale.value = newLocale
}

// 提供国际化相关功能
provide('i18n', {
  locale,
  t,
  changeLocale
})
</script>

<template>
  <div>
    <slot />
  </div>
</template>
```

#### AnyComponent.vue (任何嵌套组件)

```vue
<script setup>
import { inject } from 'vue'

const { t, locale, changeLocale } = inject('i18n')
</script>

<template>
  <div>
    <p>{{ t('hello') }}</p>
    <p>{{ t('welcome') }}</p>
    <div>
      <button @click="changeLocale('zh')" :disabled="locale === 'zh'">中文</button>
      <button @click="changeLocale('en')" :disabled="locale === 'en'">English</button>
    </div>
  </div>
</template>
```

### 场景：用户认证状态管理

#### AuthProvider.vue (顶层组件)

```vue
<script setup>
import { provide, ref, reactive } from 'vue'

const user = ref(null)
const loading = ref(false)

const login = async (username, password) => {
  loading.value = true
  try {
    // 模拟 API 调用
    await new Promise(resolve => setTimeout(resolve, 1000))
    user.value = {
      id: 1,
      username,
      name: 'John Doe'
    }
  } catch (error) {
    console.error('Login failed:', error)
  } finally {
    loading.value = false
  }
}

const logout = () => {
  user.value = null
}

const isAuthenticated = computed(() => !!user.value)

// 提供认证相关功能
provide('auth', {
  user,
  loading,
  isAuthenticated,
  login,
  logout
})
</script>

<template>
  <div>
    <slot />
  </div>
</template>
```

#### ProtectedComponent.vue (需要认证的组件)

```vue
<script setup>
import { inject } from 'vue'

const { user, isAuthenticated, login, logout } = inject('auth')

const handleLogin = () => {
  login('admin', 'password')
}
</script>

<template>
  <div>
    <template v-if="isAuthenticated">
      <p>欢迎，{{ user.name }}！</p>
      <button @click="logout">退出登录</button>
    </template>
    <template v-else>
      <p>请先登录</p>
      <button @click="handleLogin">登录</button>
    </template>
  </div>
</template>
```

## 类型安全 (TypeScript)

使用 TypeScript 时，可以为注入的数据定义类型：

```typescript
// types/theme.ts
export interface ThemeContext {
  theme: 'light' | 'dark'
  isDark: boolean
  toggleTheme: () => void
}

// 父组件
import type { ThemeContext } from './types/theme'
import { provide } from 'vue'

provide<ThemeContext>('theme', {
  theme: 'light',
  isDark: false,
  toggleTheme: () => { /* ... */ }
})

// 子组件
import { inject } from 'vue'
import type { ThemeContext } from './types/theme'

const themeContext = inject<ThemeContext>('theme')
```

## 最佳实践

### 1. 使用 Symbol 作为 key

避免命名冲突：

```javascript
// keys.js
export const THEME_KEY = Symbol('theme')
export const USER_KEY = Symbol('user')

// 父组件
import { THEME_KEY } from './keys'
provide(THEME_KEY, themeData)

// 子组件
import { THEME_KEY } from './keys'
const themeData = inject(THEME_KEY)
```

### 2. 提供响应式数据

```javascript
import { computed, provide, reactive } from 'vue'

const user = reactive({ name: 'John', age: 25 })
const isAdult = computed(() => user.age >= 18)

provide('user', {
  user,
  isAdult
})
```

### 3. 设置默认值和验证

```javascript
// 注入时设置默认值
const injectedValue = inject('key', 'default value')

// 或者使用工厂函数
const value = inject('key', () => createDefaultValue(), true)
```

### 4. 避免直接修改注入的值

```javascript
// ❌ 不推荐：直接修改
const user = inject('user')
user.name = 'New Name'

// ✅ 推荐：通过父组件提供的方法修改
const updateUser = inject('updateUser')
updateUser({ name: 'New Name' })
```

## 注意事项

### provide 和 inject 不是响应式的

- 默认情况下，注入的值不是响应式的
- 如果需要响应式，应该提供 ref 或 reactive 对象
- 只能在 setup() 或 <script setup> 中使用

### 避免过度使用

- 简单的父子通信使用 props/emits
- 复杂的状态管理考虑使用 Pinia

### 注入依赖的可选性

```javascript
// 如果依赖是必需的
const requiredValue = inject('requiredKey')
if (!requiredValue) {
  throw new Error('requiredKey 必须被提供')
}
```

## 适用场景

这种模式特别适合：

- 全局配置（主题、语言等）
- 共享工具函数
- 复杂的表单组件
- 组件库开发

## 高级用法和技巧

### 1. 组合多个 Provider

可以创建多个 Provider 来管理不同领域的状态：

```vue
<!-- App.vue -->
<template>
  <ThemeProvider>
    <I18nProvider>
      <AuthProvider>
        <RouterView />
      </AuthProvider>
    </I18nProvider>
  </ThemeProvider>
</template>
```

### 2. 使用 provide/inject 与 Composition API 结合

创建可复用的 composable 函数：

```javascript
// composables/useTheme.js
import { inject } from 'vue'

export function useTheme() {
  const themeConfig = inject('theme')
  
  if (!themeConfig) {
    throw new Error('useTheme must be used within a ThemeProvider')
  }
  
  return themeConfig
}

// 在组件中使用
import { useTheme } from '@/composables/useTheme'

const { theme, toggleTheme } = useTheme()
```

### 3. 动态注入值

可以根据条件动态提供不同的值：

```vue
<script setup>
import { provide, ref, computed } from 'vue'

const userRole = ref('guest') // 可以从认证状态获取

const permissions = computed(() => {
  if (userRole.value === 'admin') {
    return ['read', 'write', 'delete']
  } else if (userRole.value === 'user') {
    return ['read', 'write']
  }
  return ['read']
})

provide('permissions', permissions)
</script>
```

### 4. 与 Pinia/Vuex 集成

在大型应用中，可以结合 Pinia 或 Vuex 使用：

```vue
<script setup>
import { provide } from 'vue'
import { useUserStore } from '@/stores/user'

const userStore = useUserStore()

// 提供 store 的部分功能
provide('user', {
  user: computed(() => userStore.user),
  login: userStore.login,
  logout: userStore.logout
})
</script>
```

### 5. 测试策略

在测试中，可以轻松模拟 provide 的值：

```javascript
// 测试文件
import { mount } from '@vue/test-utils'
import MyComponent from '@/components/MyComponent.vue'

test('should use injected theme', () => {
  const wrapper = mount(MyComponent, {
    global: {
      provide: {
        theme: {
          theme: 'light',
          isDark: false,
          toggleTheme: vi.fn()
        }
      }
    }
  })
  
  expect(wrapper.text()).toContain('当前主题: light')
})
```

### 6. 类型推断增强

使用 TypeScript 时，可以创建类型工具来增强类型推断：

```typescript
// types/inject.ts
export function createInjectionKey<T>(key: string) {
  return Symbol(key) as InjectionKey<T>
}

// 使用
export const THEME_KEY = createInjectionKey<ThemeContext>('theme')

// 父组件
provide(THEME_KEY, themeContext)

// 子组件
const themeContext = inject(THEME_KEY) // 类型自动推断为 ThemeContext | undefined
```

## 性能优化建议

### 1. 避免在 provide 中传递复杂的计算值

对于复杂的计算，应该使用 `computed` 来缓存结果：

```javascript
// ❌ 不推荐：每次组件渲染都会重新计算
provide('expensiveValue', {
  data: heavyComputation() // 每次都会重新执行
})

// ✅ 推荐：使用 computed 缓存计算结果
import { computed } from 'vue'

const expensiveValue = computed(() => heavyComputation())
provide('expensiveValue', expensiveValue)
```

### 2. 合理使用响应式对象

- 对于不需要响应式的数据，直接提供原始值
- 对于需要响应式的数据，使用 `ref` 或 `reactive`
- 对于大型对象，考虑使用 `shallowReactive` 来减少响应式开销

```javascript
// 不需要响应式的数据
provide('API_BASE_URL', 'https://api.example.com')

// 需要响应式的数据
provide('user', reactive({ name: 'John' }))

// 大型对象使用 shallowReactive
import { shallowReactive } from 'vue'

provide('largeConfig', shallowReactive(largeConfigObject))
```

### 3. 避免过度使用 provide/inject

- 对于简单的父子通信，使用 props/emits 更高效
- 对于跨多个层级的通信，才考虑使用 provide/inject
- 对于全局状态管理，大型应用考虑使用 Pinia

### 4. 注意组件卸载时的清理

如果提供的是需要清理的资源（如定时器、事件监听器），应该在组件卸载时清理：

```vue
<script setup>
import { provide, onUnmounted } from 'vue'

const intervalId = setInterval(() => {
  console.log('Tick')
}, 1000)

provide('intervalId', intervalId)

onUnmounted(() => {
  clearInterval(intervalId)
})
</script>
```

### 5. 使用 Symbol 作为 key 的性能考虑

使用 Symbol 作为 key 可以避免命名冲突，但会增加少量内存开销。对于全局配置，这种开销是可以接受的：

```javascript
// keys.js
export const THEME_KEY = Symbol('theme')
export const USER_KEY = Symbol('user')
```

### 6. 按需注入

只注入组件实际需要的值，避免注入整个对象：

```javascript
// ❌ 不推荐：注入整个对象
const themeConfig = inject('theme')
const { toggleTheme } = themeConfig

// ✅ 推荐：直接注入需要的方法
const toggleTheme = inject('toggleTheme')
```