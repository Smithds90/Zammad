// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import domMatchers from '@testing-library/jest-dom/matchers'
import { configure } from '@testing-library/vue'
import * as matchers from 'vitest-axe/matchers'
import { expect } from 'vitest'
import 'vitest-axe/extend-expect'
import { ServiceWorkerHelper } from '@shared/utils/testSw'
import * as assertions from './support/assertions/index'

global.__ = (source) => {
  return source
}

window.sw = new ServiceWorkerHelper()

configure({
  testIdAttribute: 'data-test-id',
  asyncUtilTimeout: process.env.CI ? 30_000 : 1_000,
})

Object.defineProperty(window, 'fetch', {
  value: (path: string) => {
    throw new Error(`calling fetch on ${path}`)
  },
  writable: true,
  configurable: true,
})

class DOMRectList {
  length = 0

  // eslint-disable-next-line class-methods-use-this
  item = () => null;

  // eslint-disable-next-line class-methods-use-this
  [Symbol.iterator] = () => {
    //
  }
}

Object.defineProperty(Node.prototype, 'getClientRects', {
  value: new DOMRectList(),
})
Object.defineProperty(Element.prototype, 'scroll', { value: vi.fn() })
Object.defineProperty(Element.prototype, 'scrollBy', { value: vi.fn() })
Object.defineProperty(Element.prototype, 'scrollIntoView', { value: vi.fn() })

require.extensions['.css'] = () => ({})

vi.stubGlobal('requestAnimationFrame', (cb: () => void) => {
  setTimeout(cb, 0)
})

vi.stubGlobal('scrollTo', vi.fn())
vi.stubGlobal('matchMedia', (media: string) => ({
  matches: false,
  media,
  onchange: null,
  addEventListener: vi.fn(),
  removeEventListener: vi.fn(),
}))

vi.mock('@shared/components/CommonNotifications/composable', async () => {
  const { default: originalUseNotifications } = await vi.importActual<any>(
    '@shared/components/CommonNotifications/composable',
  )
  let notifications: any
  const useNotifications = () => {
    if (notifications) return notifications
    const result = originalUseNotifications()
    notifications = {
      notify: vi.fn(result.notify),
      notifications: result.notifications,
      removeNotification: vi.fn(result.removeNotification),
      clearAllNotifications: vi.fn(result.clearAllNotifications),
      hasErrors: vi.fn(result.hasErrors),
    }
    return notifications
  }

  return {
    useNotifications,
    default: useNotifications,
  }
})

// don't rely on tiptap, because it's not supported in JSDOM
vi.mock(
  '@shared/components/Form/fields/FieldEditor/FieldEditorInput.vue',
  async () => {
    const { computed, defineComponent } = await import('vue')
    const component = defineComponent({
      name: 'FieldEditorInput',
      props: { context: { type: Object, required: true } },
      setup(props) {
        const value = computed({
          get: () => props.context._value,
          set: (value) => {
            props.context.node.input(value)
          },
        })

        return { value, name: props.context.node.name, id: props.context.id }
      },
      template: `<textarea :id="id" :name="name" v-model="value" />`,
    })
    return { __esModule: true, default: component }
  },
)

// mock vueuse because of CommonDialog, it uses usePointerSwipe
// that is not supported in JSDOM
vi.mock('@vueuse/core', async () => {
  const mod = await vi.importActual<typeof import('@vueuse/core')>(
    '@vueuse/core',
  )
  return {
    ...mod,
    usePointerSwipe: vi
      .fn()
      .mockReturnValue({ distanceY: 0, isSwiping: false }),
  }
})

beforeEach((context) => {
  context.skipConsole = false

  if (!vi.isMockFunction(console.warn)) {
    vi.spyOn(console, 'warn').mockClear()
  } else {
    vi.mocked(console.warn).mockClear()
  }

  if (!vi.isMockFunction(console.error)) {
    vi.spyOn(console, 'error').mockClear()
  } else {
    vi.mocked(console.error).mockClear()
  }
})

afterEach((context) => {
  // we don't import it from `renderComponent`, because renderComponent may not be called
  // and it doesn't make sense to import everything from it
  if ('cleanupComponents' in globalThis) {
    globalThis.cleanupComponents()
  }

  if (context.skipConsole !== true) {
    expect(
      console.warn,
      'there were no warning during test',
    ).not.toHaveBeenCalled()
    expect(
      console.error,
      'there were no errors during test',
    ).not.toHaveBeenCalled()
  }
})

// Import the matchers for accessibility testing with aXe.
expect.extend(matchers)
expect.extend(assertions)
expect.extend(domMatchers)

expect.extend({
  // allow aria-disabled in toBeDisabled
  toBeDisabled(received, ...args) {
    if (received instanceof Element) {
      const attr = received.getAttribute('aria-disabled')
      if (!this.isNot && attr === 'true') {
        return { pass: true, message: () => '' }
      }
      if (this.isNot && attr === 'true') {
        // pass will be reversed and it will fail
        return { pass: true, message: () => 'should not have "aria-disabled"' }
      }
    }
    return (domMatchers.toBeDisabled as any).call(this, received, ...args)
  },
})

process.on('uncaughtException', (e) => console.log('Uncaught Exception', e))
process.on('unhandledRejection', (e) => console.log('Unhandled Rejection', e))

process.on('uncaughtException', (e) => console.log('Uncaught Exception', e))
process.on('unhandledRejection', (e) => console.log('Unhandled Rejection', e))

declare module 'vitest' {
  interface TestContext {
    skipConsole: boolean
  }
}

declare global {
  function cleanupComponents(): void
}
