// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

const { splitVendorChunk } = require('vite')

const graphqlChunk = ['graphql', '@apollo', '@wry']

const isGraphqlChunk = (id) =>
  graphqlChunk.some((chunk) => id.includes(`node_modules/${chunk}`))

const graphqlIds = new Set()
const matchers = [
  {
    vendor: false,
    matcher: (id) => id === 'virtual:svg-icons-register',
    chunk: 'icons',
  },
  {
    vendor: false,
    matcher: (id) => id.includes('vite/preload-helper'),
    chunk: 'vite',
  },
  {
    vendor: false,
    matcher: (id) => id.endsWith('/routes.ts'),
    chunk: 'routes',
  },
  {
    vendor: true,
    matcher: (id) => id.includes('@vue/apollo'),
    chunk: 'apollo',
  },
  {
    vendor: false,
    matcher: (id) => id.includes('frontend/shared/server'),
    chunk: 'apollo',
  },
  {
    vendor: true,
    matcher: (id) => id.includes('node_modules/lodash-es'),
    chunk: 'lodash',
  },
  {
    vendor: true,
    matcher: (id, api) => {
      const { importers, dynamicImporters } = api.getModuleInfo(id)
      const match =
        graphqlIds.has(id) ||
        isGraphqlChunk(id) ||
        importers.some(isGraphqlChunk) ||
        dynamicImporters.some(isGraphqlChunk)

      if (match) {
        dynamicImporters.forEach(() => graphqlIds.add(id))
        importers.forEach(() => graphqlIds.add(id))
      }
      return match
    },
    chunk: 'graphql',
  },
  {
    vendor: true,
    matcher: (id) => /node_modules\/@?vue/.test(id),
    chunk: 'vue',
  },
]

/**
 * @returns {import("vite").Plugin}
 */
const PluginManualChunks = () => {
  const getChunk = splitVendorChunk()

  return {
    name: 'zammad:manual-chunks',
    // eslint-disable-next-line sonarjs/cognitive-complexity
    config() {
      return {
        build: {
          rollupOptions: {
            output: {
              manualChunks(id, api) {
                const chunk = getChunk(id, api)

                // FieldEditor is a special case, it's a dynamic import with a large dependency
                if (!chunk && id.includes('FieldEditor')) {
                  return
                }

                if (!chunk) {
                  for (const { vendor, matcher, chunk } of matchers) {
                    if (vendor === false && matcher(id)) {
                      return chunk
                    }
                  }
                }

                if (chunk !== 'vendor') return chunk

                for (const { vendor, matcher, chunk } of matchers) {
                  if (vendor === true && matcher(id, api)) {
                    return chunk
                  }
                }

                return 'vendor'
              },
            },
          },
        },
      }
    },
  }
}

module.exports = PluginManualChunks
