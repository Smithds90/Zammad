# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Ticket::Selector::Sql do
  context 'when relative time range is selected in ticket selector' do
    def get_condition(operator, range)
      {
        'ticket.created_at' => {
          operator: operator,
          range:    range, # minute|hour|day|month|
          value:    '10',
        },
      }
    end

    before do
      freeze_time
    end

    it 'calculates proper time interval, when operator is within last relative' do
      condition = get_condition('within last (relative)', 'minute')

      _, bind_params = Ticket.selector2sql(condition)

      expect(bind_params).to eq([10.minutes.ago, Time.zone.now])
    end

    it 'calculates proper time interval, when operator is within next relative' do
      condition = get_condition('within next (relative)', 'hour')

      _, bind_params = Ticket.selector2sql(condition)

      expect(bind_params).to eq([Time.zone.now, 10.hours.from_now])
    end

    it 'calculates proper time interval, when operator is before (relative)' do
      condition = get_condition('before (relative)', 'day')

      _, bind_params = Ticket.selector2sql(condition)

      expect(bind_params).to eq([10.days.ago])
    end

    it 'calculates proper time interval, when operator is after (relative)' do
      condition = get_condition('after (relative)', 'week')

      _, bind_params = Ticket.selector2sql(condition)

      expect(bind_params).to eq([10.weeks.from_now])
    end

    it 'calculates proper time interval, when operator is till (relative)' do
      condition = get_condition('till (relative)', 'month')

      _, bind_params = Ticket.selector2sql(condition)

      expect(bind_params).to eq([10.months.from_now])
    end

    it 'calculates proper time interval, when operator is from (relative)' do
      condition = get_condition('from (relative)', 'year')

      _, bind_params = Ticket.selector2sql(condition)

      expect(bind_params).to eq([10.years.ago])
    end

    context 'when today operator is used' do
      before do
        travel_to '2022-10-11 14:40:00'
        Setting.set('timezone_default', 'Europe/Berlin')
      end

      it 'calculates proper time interval when today operator is used', :aggregate_failures do
        _, bind_params = Ticket.selector2sql({ 'ticket.created_at' => { 'operator' => 'today' } })

        Time.use_zone(Setting.get('timezone_default_sanitized').presence) do
          expect(bind_params[0].to_s).to eq('2022-10-10 22:00:00 UTC')
          expect(bind_params[1].to_s).to eq('2022-10-11 21:59:59 UTC')
        end
      end
    end
  end

  describe 'Expert mode overview not working when using "owner is me" OR "subscribe is me #4547' do
    let(:agent)    { create(:agent, groups: [Group.first]) }
    let(:ticket_1) { create(:ticket, owner: agent, group: Group.first) }
    let(:ticket_2) { create(:ticket, group: Group.first) }
    let(:ticket_3) { create(:ticket, owner: agent, group: Group.first) }

    before do
      Ticket.destroy_all

      ticket_1 && ticket_2 && ticket_3
      create(:mention, mentionable: ticket_2, user: agent)
      create(:mention, mentionable: ticket_3, user: agent)
    end

    it 'does return 1 mentioned ticket' do
      condition = {
        operator:   'AND',
        conditions: [
          {
            name:          'ticket.mention_user_ids',
            operator:      'is',
            pre_condition: 'specific',
            value:         agent.id,
          }
        ]
      }

      count, = Ticket.selectors(condition, { current_user: agent })
      expect(count).to eq(2)
    end

    it 'does return 1 owned ticket' do
      condition = {
        operator:   'AND',
        conditions: [
          {
            name:          'ticket.owner_id',
            operator:      'is',
            pre_condition: 'specific',
            value:         agent.id,
          }
        ]
      }

      count, = Ticket.selectors(condition, { current_user: agent })
      expect(count).to eq(2)
    end

    it 'does return 1 owned & subscribed ticket' do
      condition = {
        operator:   'AND',
        conditions: [
          {
            name:          'ticket.mention_user_ids',
            operator:      'is',
            pre_condition: 'specific',
            value:         agent.id,
          },
          {
            name:          'ticket.owner_id',
            operator:      'is',
            pre_condition: 'specific',
            value:         agent.id,
          }
        ]
      }

      count, = Ticket.selectors(condition, { current_user: agent })
      expect(count).to eq(1)
    end

    it 'does return 3 owned or subscribed tickets' do
      condition = {
        operator:   'OR',
        conditions: [
          {
            name:          'ticket.mention_user_ids',
            operator:      'is',
            pre_condition: 'specific',
            value:         agent.id,
          },
          {
            name:          'ticket.owner_id',
            operator:      'is',
            pre_condition: 'specific',
            value:         agent.id,
          }
        ]
      }

      count, = Ticket.selectors(condition, { current_user: agent })
      expect(count).to eq(3)
    end
  end

  describe 'Overviews: "Organization" does not work as a pre-condition in the expert mode #4557' do
    let(:agent) { create(:agent, groups: [Group.first]) }
    let(:organization) { create(:organization) }
    let(:customer_1)   { create(:customer) }
    let(:customer_2)   { create(:customer, organization: organization) }
    let(:ticket_1)     { create(:ticket, customer: customer_1, group: Group.first) }
    let(:ticket_2)     { create(:ticket, customer: customer_2, group: Group.first) }

    before do
      Ticket.destroy_all
      ticket_1 && ticket_2
    end

    it 'does return 1 customer ticket without organization' do
      condition = {
        operator:   'AND',
        conditions: [
          {
            name:          'ticket.organization_id',
            operator:      'is',
            pre_condition: 'not_set',
          }
        ]
      }

      count, = Ticket.selectors(condition, { current_user: agent })
      expect(count).to eq(1)
    end

    it 'does return 1 ticket with organization title' do
      condition = {
        operator:   'AND',
        conditions: [
          {
            name:     'organization.name',
            operator: 'is',
            value:    organization.name,
          }
        ]
      }

      count, = Ticket.selectors(condition, { current_user: agent })
      expect(count).to eq(1)
    end

    it 'does return 1 ticket with organization and name' do
      condition = {
        operator:   'AND',
        conditions: [
          {
            name:          'ticket.organization_id',
            operator:      'is not',
            pre_condition: 'not_set',
          },
          {
            name:     'organization.name',
            operator: 'is',
            value:    organization.name,
          }
        ]
      }

      count, = Ticket.selectors(condition, { current_user: agent })
      expect(count).to eq(1)
    end

    it 'does return 1 ticket without organization OR NO name' do
      condition = {
        operator:   'OR',
        conditions: [
          {
            name:          'ticket.organization_id',
            operator:      'is',
            pre_condition: 'not_set',
          },
          {
            name:     'organization.name',
            operator: 'is not',
            value:    organization.name,
          }
        ]
      }

      count, = Ticket.selectors(condition, { current_user: agent })
      expect(count).to eq(1)
    end
  end
end
