# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

module ChecksClientNotification
  extend ActiveSupport::Concern

  included do
    after_create  :notify_clients_after_create
    after_update  :notify_clients_after_update
    after_touch   :notify_clients_after_touch
    after_destroy :notify_clients_after_destroy
  end

  def notify_clients_data(event)
    class_name = self.class.name.gsub(/::/, '')

    {
      message: {
        event: "#{class_name}:#{event}",
        data:  { id: id, updated_at: updated_at }
      },
      type:    'authenticated',
    }
  end

  def notify_clients_send(data)
    return notify_clients_send_to(data[:message]) if client_notification_send_to.present?

    PushMessages.send(data)
  end

  def notify_clients_send_to(data)
    client_notification_send_to.each do |user_id|
      PushMessages.send_to(send(user_id), data)
    end
  end

  def notify_clients_after_create

    # return if we run import mode
    return if Setting.get('import_mode')

    # skip if ignored
    return if client_notification_events_ignored.include?(:create)

    logger.debug { "#{self.class.name}.find(#{id}) notify created #{created_at}" }

    data = notify_clients_data(:create)
    notify_clients_send(data)
  end

  def notify_clients_after_update

    # return if we run import mode
    return if Setting.get('import_mode')

    # skip if ignored
    return if client_notification_events_ignored.include?(:update)

    logger.debug { "#{self.class.name}.find(#{id}) notify UPDATED #{updated_at}" }

    data = notify_clients_data(:update)
    notify_clients_send(data)
  end

  def notify_clients_after_touch

    # return if we run import mode
    return if Setting.get('import_mode')

    # skip if ignored
    return if client_notification_events_ignored.include?(:touch)

    logger.debug { "#{self.class.name}.find(#{id}) notify TOUCH #{updated_at}" }

    data = notify_clients_data(:touch)
    notify_clients_send(data)
  end

  def notify_clients_after_destroy

    # return if we run import mode
    return if Setting.get('import_mode')

    # skip if ignored
    return if client_notification_events_ignored.include?(:destroy)

    logger.debug { "#{self.class.name}.find(#{id}) notify DESTOY #{updated_at}" }

    data = notify_clients_data(:destroy)
    notify_clients_send(data)
  end

  private

  def client_notification_events_ignored
    @client_notification_events_ignored ||= self.class.instance_variable_get(:@client_notification_events_ignored) || []
  end

  def client_notification_send_to
    @client_notification_send_to ||= self.class.instance_variable_get(:@client_notification_send_to) || []
  end

  # methods defined here are going to extend the class, not the instance of it
  class_methods do

=begin

serve method to ignore events

class Model < ApplicationModel
  include ChecksClientNotification
  client_notification_events_ignored :create, :update, :touch
end

=end

    def client_notification_events_ignored(*attributes)
      @client_notification_events_ignored ||= []
      @client_notification_events_ignored |= attributes
    end

=begin

serve method to define recipient user ids

class Model < ApplicationModel
  include ChecksClientNotification
  client_notification_send_to :user_id
end

=end

    def client_notification_send_to(*attributes)
      @client_notification_send_to ||= []
      @client_notification_send_to |= attributes
    end

  end

end
