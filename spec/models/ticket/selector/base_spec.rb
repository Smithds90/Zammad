# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Ticket::Selector::Base, searchindex: true do
  let(:agent)    { create(:agent, groups: [Group.first]) }
  let(:ticket_1) { create(:ticket, title: 'bli', group: Group.first) }
  let(:ticket_2) { create(:ticket, title: 'bla', group: Group.first) }
  let(:ticket_3) { create(:ticket, title: 'blub', group: Group.first) }

  before do
    Ticket.destroy_all
    ticket_1 && ticket_2 && ticket_3
    searchindex_model_reload([Ticket])
  end

  it 'does support AND conditions', :aggregate_failures do
    condition = {
      operator:   'AND',
      conditions: [
        {
          name:     'ticket.title',
          operator: 'contains',
          value:    'b',
        },
        {
          name:     'ticket.title',
          operator: 'contains',
          value:    'l',
        },
        {
          name:     'ticket.title',
          operator: 'contains',
          value:    'b',
        },
      ]
    }

    count, = Ticket.selectors(condition, { current_user: agent })
    expect(count).to eq(3)

    result = SearchIndexBackend.selectors('Ticket', condition, { current_user: agent })
    expect(result[:count]).to eq(3)
  end

  it 'does support NOT conditions', :aggregate_failures do
    condition = {
      operator:   'NOT',
      conditions: [
        {
          name:     'ticket.title',
          operator: 'contains',
          value:    'b',
        },
        {
          name:     'ticket.title',
          operator: 'contains',
          value:    'l',
        },
        {
          name:     'ticket.title',
          operator: 'contains',
          value:    'b',
        },
      ]
    }

    count, = Ticket.selectors(condition, { current_user: agent })
    expect(count).to eq(0)

    result = SearchIndexBackend.selectors('Ticket', condition, { current_user: agent })
    expect(result[:count]).to eq(0)
  end

  it 'does support OR conditions', :aggregate_failures do
    condition = {
      operator:   'OR',
      conditions: [
        {
          name:     'ticket.title',
          operator: 'is',
          value:    'bli',
        },
        {
          name:     'ticket.title',
          operator: 'is',
          value:    'bla',
        },
        {
          name:     'ticket.title',
          operator: 'is',
          value:    'blub',
        },
      ]
    }

    count, = Ticket.selectors(condition, { current_user: agent })
    expect(count).to eq(3)

    result = SearchIndexBackend.selectors('Ticket', condition, { current_user: agent })
    expect(result[:count]).to eq(3)
  end

  it 'does support OR conditions (one missing)', :aggregate_failures do
    condition = {
      operator:   'OR',
      conditions: [
        {
          name:     'ticket.title',
          operator: 'is',
          value:    'xxx',
        },
        {
          name:     'ticket.title',
          operator: 'is',
          value:    'bla',
        },
        {
          name:     'ticket.title',
          operator: 'is',
          value:    'blub',
        },
      ]
    }

    count, = Ticket.selectors(condition, { current_user: agent })
    expect(count).to eq(2)

    result = SearchIndexBackend.selectors('Ticket', condition, { current_user: agent })
    expect(result[:count]).to eq(2)
  end

  it 'does support OR conditions (all missing)', :aggregate_failures do
    condition = {
      operator:   'AND',
      conditions: [
        {
          name:     'ticket.title',
          operator: 'is',
          value:    'bli',
        },
        {
          name:     'ticket.title',
          operator: 'is',
          value:    'bla',
        },
        {
          name:     'ticket.title',
          operator: 'is',
          value:    'blub',
        },
      ]
    }

    count, = Ticket.selectors(condition, { current_user: agent })
    expect(count).to eq(0)

    result = SearchIndexBackend.selectors('Ticket', condition, { current_user: agent })
    expect(result[:count]).to eq(0)
  end

  it 'does support sub level conditions', :aggregate_failures do
    condition = {
      operator:   'OR',
      conditions: [
        {
          name:     'ticket.title',
          operator: 'is',
          value:    'bli',
        },
        {
          operator:   'OR',
          conditions: [
            {
              name:     'ticket.title',
              operator: 'is',
              value:    'bla',
            },
            {
              name:     'ticket.title',
              operator: 'is',
              value:    'blub',
            },
          ],
        }
      ]
    }

    count, = Ticket.selectors(condition, { current_user: agent })
    expect(count).to eq(3)

    result = SearchIndexBackend.selectors('Ticket', condition, { current_user: agent })
    expect(result[:count]).to eq(3)
  end

  it 'does support sub level conditions (one missing)', :aggregate_failures do
    condition = {
      operator:   'OR',
      conditions: [
        {
          name:     'ticket.title',
          operator: 'is',
          value:    'bli',
        },
        {
          operator:   'OR',
          conditions: [
            {
              name:     'ticket.title',
              operator: 'is',
              value:    'xxx',
            },
            {
              name:     'ticket.title',
              operator: 'is',
              value:    'blub',
            },
          ],
        }
      ]
    }

    count, = Ticket.selectors(condition, { current_user: agent })
    expect(count).to eq(2)

    result = SearchIndexBackend.selectors('Ticket', condition, { current_user: agent })
    expect(result[:count]).to eq(2)
  end

  it 'does support sub level conditions (all missing)', :aggregate_failures do
    condition = {
      operator:   'AND',
      conditions: [
        {
          name:     'ticket.title',
          operator: 'is',
          value:    'bli',
        },
        {
          operator:   'AND',
          conditions: [
            {
              name:     'ticket.title',
              operator: 'is',
              value:    'bla',
            },
            {
              name:     'ticket.title',
              operator: 'is',
              value:    'blub',
            },
          ],
        }
      ]
    }

    count, = Ticket.selectors(condition, { current_user: agent })
    expect(count).to eq(0)

    result = SearchIndexBackend.selectors('Ticket', condition, { current_user: agent })
    expect(result[:count]).to eq(0)
  end

  it 'does return all 3 results on empty condition', :aggregate_failures do
    condition = {
      operator:   'AND',
      conditions: []
    }

    count, = Ticket.selectors(condition, { current_user: agent })
    expect(count).to eq(3)

    result = SearchIndexBackend.selectors('Ticket', condition, { current_user: agent })
    expect(result[:count]).to eq(3)
  end

  it 'does return all 3 results on empty sub condition', :aggregate_failures do
    condition = {
      operator:   'AND',
      conditions: [
        {
          name:     'ticket.title',
          operator: 'contains',
          value:    'b',
        },
        {
          name:     'ticket.title',
          operator: 'contains',
          value:    'l',
        },
        {
          name:     'ticket.title',
          operator: 'contains',
          value:    'b',
        },
        {
          operator:   'AND',
          conditions: [
          ],
        }
      ]
    }

    count, = Ticket.selectors(condition, { current_user: agent })
    expect(count).to eq(3)

    result = SearchIndexBackend.selectors('Ticket', condition, { current_user: agent })
    expect(result[:count]).to eq(3)
  end

  it 'does return all 3 results on empty sub sub condition', :aggregate_failures do
    condition = {
      operator:   'AND',
      conditions: [
        {
          name:     'ticket.title',
          operator: 'contains',
          value:    'b',
        },
        {
          name:     'ticket.title',
          operator: 'contains',
          value:    'l',
        },
        {
          name:     'ticket.title',
          operator: 'contains',
          value:    'b',
        },
        {
          operator:   'AND',
          conditions: [
            {
              operator:   'AND',
              conditions: [
              ],
            }
          ],
        }
      ]
    }

    count, = Ticket.selectors(condition, { current_user: agent })
    expect(count).to eq(3)

    result = SearchIndexBackend.selectors('Ticket', condition, { current_user: agent })
    expect(result[:count]).to eq(3)
  end

  describe 'Trigger do not allow "Multi-Tree-Select" Fields on Organization and User Level as If Condition #4504', db_strategy: :reset do
    let(:field_name) { SecureRandom.uuid }
    let(:organization) { create(:organization, field_name => ['Incident', 'Incident::Hardware']) }
    let(:customer)     { create(:customer, organization: organization, field_name => ['Incident', 'Incident::Hardware']) }
    let(:ticket)       { create(:ticket, title: 'bli', group: Group.first, customer: customer, field_name => ['Incident', 'Incident::Hardware']) }

    def check_condition(attribute)
      condition = {
        operator:   'AND',
        conditions: [
          {
            name:     attribute.to_s,
            operator: 'contains all',
            value:    ['Incident', 'Incident::Hardware'],
          }
        ]
      }

      count, = Ticket.selectors(condition, { current_user: agent })
      expect(count).to eq(1)

      count, = Ticket.selectors(condition, { current_user: agent })
      expect(count).to eq(1)
    end

    before do
      create(:object_manager_attribute_multi_tree_select, object_name: 'Ticket', name: field_name)
      create(:object_manager_attribute_multi_tree_select, object_name: 'User', name: field_name)
      create(:object_manager_attribute_multi_tree_select, object_name: 'Organization', name: field_name)
      ObjectManager::Attribute.migration_execute
      ticket
      searchindex_model_reload([Ticket, User, Organization])
    end

    it 'does support contains one for all objects' do # rubocop:disable RSpec/NoExpectationExample
      check_condition("ticket.#{field_name}")
      check_condition("customer.#{field_name}")
      check_condition("organization.#{field_name}")
    end
  end

  describe 'Reporting profiles do not work with multi tree select #4546' do
    context 'when value is a string' do
      before do
        create(:tag, tag_item: create(:'tag/item', name: 'AAA'), o: ticket_1)
        create(:tag, tag_item: create(:'tag/item', name: 'BBB'), o: ticket_1)
        searchindex_model_reload([Ticket])
      end

      it 'does return ticket by contains all string value', :aggregate_failures do
        condition = {
          operator:   'AND',
          conditions: [
            {
              name:     'ticket.tags',
              operator: 'contains all',
              value:    'AAA, BBB',
            }
          ]
        }

        count, = Ticket.selectors(condition, { current_user: agent })
        expect(count).to eq(1)

        result = SearchIndexBackend.selectors('Ticket', condition, { current_user: agent })
        expect(result[:count]).to eq(1)
      end
    end

    context 'when value is an array', db_strategy: :reset do
      let(:field_name) { SecureRandom.uuid }

      before do
        create(:object_manager_attribute_multi_tree_select, name: field_name)
        ObjectManager::Attribute.migration_execute
        ticket_1.reload.update(field_name => ['Incident', 'Incident::Hardware'])
        searchindex_model_reload([Ticket])
      end

      it 'does return ticket by contains all array value', :aggregate_failures do
        condition = {
          operator:   'AND',
          conditions: [
            {
              name:     "ticket.#{field_name}",
              operator: 'contains all',
              value:    ['Incident', 'Incident::Hardware'],
            }
          ]
        }

        count, = Ticket.selectors(condition, { current_user: agent })
        expect(count).to eq(1)

        result = SearchIndexBackend.selectors('Ticket', condition, { current_user: agent })
        expect(result[:count]).to eq(1)
      end
    end
  end
end
