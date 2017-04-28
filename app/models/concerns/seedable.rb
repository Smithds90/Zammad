# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/
module Seedable
  extend ActiveSupport::Concern

  # methods defined here are going to extend the class, not the instance of it
  class_methods do

    def reseed
      destroy_all
      seed
    end

    def seed
      UserInfo.ensure_current_user_id do
        load seedfile
      end
    end

    def seedfile
      "#{Rails.root}/db/seeds/#{name.pluralize.underscore}.rb"
    end
  end
end
