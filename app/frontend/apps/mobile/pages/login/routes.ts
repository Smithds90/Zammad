// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { RouteRecordRaw } from 'vue-router'

export const isMainRoute = true

const route: RouteRecordRaw[] = [
  {
    path: '/login',
    name: 'Login',
    component: () => import('./views/Login.vue'),
    meta: {
      title: __('Sign in'),
      requiresAuth: false,
      requiredPermission: null,
      hasOwnLandmarks: true,
    },
  },
  {
    path: '/logout',
    name: 'Logout',
    component: {
      async beforeRouteEnter() {
        const [{ useAuthenticationStore }, { useNotifications }] =
          await Promise.all([
            import('@shared/stores/authentication'),
            import('@shared/components/CommonNotifications/composable'),
          ])

        const { clearAllNotifications } = useNotifications()

        const authentication = useAuthenticationStore()

        clearAllNotifications()
        await authentication.logout()

        if (authentication.externalLogout) return false

        return '/login'
      },
    },
    meta: {
      requiresAuth: false,
      requiredPermission: null,
    },
  },
]

export default route
