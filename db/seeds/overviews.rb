# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

overview_role = Role.find_by(name: 'Agent')

Overview.create_if_not_exists(
  name:      __('Unassigned tickets'),
  link:      'all_unassigned',
  prio:      1000,
  role_ids:  [overview_role.id],
  condition: {
    'ticket.owner_id' => {
      operator:      'is',
      pre_condition: 'not_set',
    },
  },
  order:     {
    by:        'created_at',
    direction: 'ASC',
  },
  view:      {
    d:                 %w[title customer group created_at],
    s:                 %w[title customer group created_at],
    m:                 %w[number title customer group created_at],
    view_mode_default: 's',
  },
)

Overview.create_if_not_exists(
  name:      __('My new/open tickets'),
  link:      'my_assigned',
  prio:      1010,
  role_ids:  [overview_role.id],
  condition: {
    'ticket.state_id' => {
      operator: 'is',
      value:    Ticket::State.by_category(:work_on).pluck(:id),
    },
    'ticket.owner_id' => {
      operator:      'is',
      pre_condition: 'current_user.id',
    },
  },
  order:     {
    by:        'created_at',
    direction: 'ASC',
  },
  view:      {
    d:                 %w[title customer group created_at],
    s:                 %w[title customer group created_at],
    m:                 %w[number title customer group created_at],
    view_mode_default: 's',
  },
)

Overview.create_if_not_exists(
  name:      __('My pending reached tickets'),
  link:      'my_pending_reached',
  prio:      1020,
  role_ids:  [overview_role.id],
  condition: {
    'ticket.state_id'     => {
      operator: 'is',
      value:    Ticket::State.by_category(:pending_reminder).pluck(:id),
    },
    'ticket.owner_id'     => {
      operator:      'is',
      pre_condition: 'current_user.id',
    },
    'ticket.pending_time' => {
      operator: 'before (relative)',
      value:    0,
      range:    'minute',
    },
  },
  order:     {
    by:        'created_at',
    direction: 'ASC',
  },
  view:      {
    d:                 %w[title customer group created_at],
    s:                 %w[title customer group created_at],
    m:                 %w[number title customer group created_at],
    view_mode_default: 's',
  },
)

Overview.create_if_not_exists(
  name:      __('My pending tickets'),
  link:      'my_pending',
  prio:      1030,
  role_ids:  [overview_role.id],
  condition: {
    'ticket.state_id'     => {
      operator: 'is',
      value:    Ticket::State.by_category(:pending).pluck(:id),
    },
    'ticket.owner_id'     => {
      operator:      'is',
      pre_condition: 'current_user.id',
    },
    'ticket.pending_time' => {
      operator: 'from (relative)',
      value:    0,
      range:    'minute',
    },
  },
  order:     {
    by:        'created_at',
    direction: 'ASC',
  },
  view:      {
    d:                 %w[title customer group created_at],
    s:                 %w[title customer group created_at],
    m:                 %w[number title customer group created_at],
    view_mode_default: 's',
  },
)

Overview.create_if_not_exists(
  name:          __('My replacement tickets'),
  link:          'my_replacement_tickets',
  prio:          1040,
  role_ids:      [overview_role.id],
  out_of_office: true,
  condition:     {
    'ticket.state_id'                     => {
      operator: 'is',
      value:    Ticket::State.by_category(:open).pluck(:id),
    },
    'ticket.out_of_office_replacement_id' => {
      operator:      'is',
      pre_condition: 'current_user.id',
    },
  },
  order:         {
    by:        'created_at',
    direction: 'DESC',
  },
  view:          {
    d:                 %w[title customer group owner escalation_at],
    s:                 %w[title customer group owner escalation_at],
    m:                 %w[number title customer group owner escalation_at],
    view_mode_default: 's',
  },
)

Overview.create_if_not_exists(
  name:      __('My subscribed tickets'),
  link:      'my_subscribed_tickets',
  prio:      1050,
  role_ids:  [overview_role.id],
  condition: { 'ticket.mention_user_ids'=>{ 'operator' => 'is', 'pre_condition' => 'current_user.id', 'value' => '', 'value_completion' => '' } },
  order:     {
    by:        'created_at',
    direction: 'ASC',
  },
  view:      {
    d:                 %w[title customer group created_at],
    s:                 %w[title customer group created_at],
    m:                 %w[number title customer group created_at],
    view_mode_default: 's',
  },
)

Overview.create_if_not_exists(
  name:      __('All open tickets'),
  link:      'all_open',
  prio:      1060,
  role_ids:  [overview_role.id],
  condition: {
    'ticket.state_id' => {
      operator: 'is',
      value:    Ticket::State.by_category(:work_on).pluck(:id),
    },
  },
  order:     {
    by:        'created_at',
    direction: 'ASC',
  },
  view:      {
    d:                 %w[title customer group state owner created_at],
    s:                 %w[title customer group state owner created_at],
    m:                 %w[number title customer group state owner created_at],
    view_mode_default: 's',
  },
)

Overview.create_if_not_exists(
  name:      __('All escalated tickets'),
  link:      'all_escalated',
  prio:      1070,
  role_ids:  [overview_role.id],
  condition: {
    'ticket.escalation_at' => {
      operator: 'till (relative)',
      value:    '10',
      range:    'minute',
    },
  },
  order:     {
    by:        'escalation_at',
    direction: 'ASC',
  },
  view:      {
    d:                 %w[title customer group owner escalation_at],
    s:                 %w[title customer group owner escalation_at],
    m:                 %w[number title customer group owner escalation_at],
    view_mode_default: 's',
  },
)

overview_role = Role.find_by(name: 'Customer')
Overview.create_if_not_exists(
  name:      __('My tickets'),
  link:      'my_tickets',
  prio:      1100,
  role_ids:  [overview_role.id],
  condition: {
    'ticket.state_id'    => {
      operator: 'is',
      value:    Ticket::State.by_category(:viewable).pluck(:id),
    },
    'ticket.customer_id' => {
      operator:      'is',
      pre_condition: 'current_user.id',
    },
  },
  order:     {
    by:        'created_at',
    direction: 'DESC',
  },
  view:      {
    d:                 %w[title customer state created_at],
    s:                 %w[number title state created_at],
    m:                 %w[number title state created_at],
    view_mode_default: 's',
  },
)
Overview.create_if_not_exists(
  name:                __('My organization tickets'),
  link:                'my_organization_tickets',
  prio:                1200,
  role_ids:            [overview_role.id],
  organization_shared: true,
  condition:           {
    'ticket.state_id'        => {
      operator: 'is',
      value:    Ticket::State.by_category(:viewable).pluck(:id),
    },
    'ticket.organization_id' => {
      operator:      'is',
      pre_condition: 'current_user.organization_id',
    },
  },
  order:               {
    by:        'created_at',
    direction: 'DESC',
  },
  view:                {
    d:                 %w[title customer organization state created_at],
    s:                 %w[number title customer organization state created_at],
    m:                 %w[number title customer organization state created_at],
    view_mode_default: 's',
  },
)
