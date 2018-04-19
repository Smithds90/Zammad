class AddInputToTicketCreate < ActiveRecord::Migration[5.1]
  def up
    # return if it's a new setup
    return if !Setting.find_by(name: 'system_init_done')

    ObjectManager::Attribute.add(
        force: true,
        object: 'Ticket',
        name: 'organization_id',
        display: 'Organization',
        data_type: 'select',
        data_option: {
            relation: 'Organization',
            nulloption: false,
            multiple: false,
            null: false,
            default: 0,
            translate: true
        },
        editable: false,
        active: true,

        screens: {
          create_middle_org: {
            'ticket.agent' =>  {
              null: false,
              default: 0,
              item_class: 'column'
            },
            'ticket.customer' => {
              null: false,
              default: 0,
              item_class: 'two-columns'
            },
          },
        },
        to_create: false,
        to_migrate: false,
        to_delete: false,
        position: 45,
        updated_by_id: 1,
        created_by_id: 1,
    )

    Cache.clear
  end
end
