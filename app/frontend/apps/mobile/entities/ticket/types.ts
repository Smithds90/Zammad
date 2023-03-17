// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { ComputedRef, Ref, ShallowRef } from 'vue'
import type {
  TicketById,
  TicketLiveAppUser,
} from '@shared/entities/ticket/types'
import type { FormRef, FormValues } from '@shared/components/Form'
import type { TicketQuery, TicketQueryVariables } from '@shared/graphql/types'
import type { QueryHandler } from '@shared/server/apollo/handler'

export interface TicketInformation {
  ticketQuery: QueryHandler<TicketQuery, TicketQueryVariables>
  initialFormTicketValue: FormValues
  ticket: ComputedRef<TicketById | undefined>
  newTicketArticleRequested: Ref<boolean>
  newTicketArticlePresent: Ref<boolean>
  form: ShallowRef<FormRef | undefined>
  updateFormLocation: (newLocation: string) => void
  canUpdateTicket: ComputedRef<boolean>
  showArticleReplyDialog: () => void
  liveUserList?: Ref<TicketLiveAppUser[]>
  refetchingStatus: Ref<boolean>
  updateRefetchingStatus: (newStatus: boolean) => void
}
