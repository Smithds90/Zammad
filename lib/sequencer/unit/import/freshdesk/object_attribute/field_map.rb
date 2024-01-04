# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Freshdesk::ObjectAttribute::FieldMap < Sequencer::Unit::Base
  prepend ::Sequencer::Unit::Import::Common::Model::Mixin::Skip::Action

  skip_any_action

  optional :action

  uses :field_map, :model_class, :resource, :sanitized_name

  def process
    field_map[model_class.name] ||= {}
    field_map[model_class.name][ resource['name'] ] = sanitized_name
  end
end
