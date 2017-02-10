# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

class Signature < ApplicationModel
  include LatestChangeObserved

  has_many  :groups,  after_add: :cache_update, after_remove: :cache_update
  validates :name,    presence: true
end
