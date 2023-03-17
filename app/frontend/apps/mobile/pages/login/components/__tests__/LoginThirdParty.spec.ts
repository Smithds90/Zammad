// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '@tests/support/components'
import LoginThirdParty from '../LoginThirdParty.vue'

const renderLoginThirdParty = () => {
  return renderComponent(LoginThirdParty, {
    props: {
      providers: [
        {
          name: 'GitHub',
          enabled: true,
          icon: 'github',
          url: '/auth/github',
        },
        {
          name: 'GitLab',
          enabled: true,
          icon: 'gitlab',
          url: '/auth/gitlab',
        },
        {
          name: 'SAML',
          enabled: true,
          icon: 'saml',
          url: '/auth/saml',
        },
      ],
    },
  })
}

describe('LoginThirdParty.vue', () => {
  it('shows the third-party login buttons', () => {
    const view = renderLoginThirdParty()

    expect(view.getByText('SAML')).toBeInTheDocument()
    expect(view.getByText('GitHub')).toBeInTheDocument()
    expect(view.getByText('GitLab')).toBeInTheDocument()

    expect(view.getByIconName('mobile-saml')).toBeInTheDocument()
    expect(view.getByIconName('mobile-github')).toBeInTheDocument()
    expect(view.getByIconName('mobile-gitlab')).toBeInTheDocument()
  })
})
