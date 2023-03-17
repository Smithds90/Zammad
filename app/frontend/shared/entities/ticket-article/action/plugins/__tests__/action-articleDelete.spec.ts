// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { TicketView } from '@shared/entities/ticket/types'
import { defaultTicket } from '@mobile/pages/ticket/__tests__/mocks/detail-view'
import { mockApplicationConfig } from '@tests/support/mock-applicationConfig'
import { setupView } from '@tests/support/mock-user'
import { createTicketArticle, createTestArticleActions } from './utils'

const createDeletableArticle = (
  userId = '123',
  isCommunication = false,
  isInternal = true,
  createdAt: Date = new Date(),
) => {
  const article = createTicketArticle()
  article.author!.id = userId
  article.type!.communication = isCommunication
  article.internal = isInternal
  article.createdAt = createdAt.toISOString()
  return article
}

describe('article delete action', () => {
  it('returns article delete for editable ticket', () => {
    setupView('agent')
    const { ticket } = defaultTicket({ update: true })
    const article = createDeletableArticle()
    const actions = createTestArticleActions(ticket, article)
    expect(actions.find((a) => a.name === 'articleDelete')).toBeDefined()
  })

  it('does not return article delete for article created by another user', () => {
    setupView('agent')
    const { ticket } = defaultTicket({ update: true })
    const article = createDeletableArticle('456')
    const actions = createTestArticleActions(ticket, article)
    expect(actions.find((a) => a.name === 'articleDelete')).toBeUndefined()
  })

  it('does not return article delete for communication article', () => {
    setupView('agent')
    const { ticket } = defaultTicket({ update: true })
    const article = createDeletableArticle('123', true, false)
    const actions = createTestArticleActions(ticket, article)
    expect(actions.find((a) => a.name === 'articleDelete')).toBeUndefined()
  })

  it('returns article delete for internal communication article', () => {
    setupView('agent')
    const { ticket } = defaultTicket({ update: true })
    const article = createDeletableArticle('123', true, true)
    const actions = createTestArticleActions(ticket, article)
    expect(actions.find((a) => a.name === 'articleDelete')).toBeDefined()
  })

  it('does not return article delete for old article', () => {
    mockApplicationConfig({ ui_ticket_zoom_article_delete_timeframe: 600 })
    setupView('agent')
    const { ticket } = defaultTicket({ update: true })
    const article = createDeletableArticle(
      '123',
      false,
      false,
      new Date('1999 12 31'),
    )
    const actions = createTestArticleActions(ticket, article)
    expect(actions.find((a) => a.name === 'articleDelete')).toBeUndefined()
  })

  it('returns article delete for old article if delete timeframe is disabled', () => {
    mockApplicationConfig({ ui_ticket_zoom_article_delete_timeframe: null })
    setupView('agent')
    const { ticket } = defaultTicket({ update: true })
    const article = createDeletableArticle(
      '123',
      false,
      false,
      new Date('1999 12 31'),
    )
    const actions = createTestArticleActions(ticket, article)
    expect(actions.find((a) => a.name === 'articleDelete')).toBeDefined()
  })

  const views: TicketView[] = ['agent', 'customer']
  it.each(views)(
    "doesn't return article delete for non-editable tickets %s",
    (view) => {
      setupView(view)
      const { ticket } = defaultTicket()
      ticket.policy.update = false
      const article = createDeletableArticle()
      const actions = createTestArticleActions(ticket, article)
      expect(actions.find((a) => a.name === 'articleDelete')).toBeUndefined()
    },
  )

  it("doesn't return article delete for customer", () => {
    setupView('customer')
    const { ticket } = defaultTicket()
    const article = createTicketArticle()
    const actions = createTestArticleActions(ticket, article)
    expect(actions.find((a) => a.name === 'articleDelete')).toBeUndefined()
  })
})
