require 'rails_helper'

RSpec.describe Webhooks::NotificationJob, type: :job do

  describe '#perform' do
    it 'sends a post request to webhook URL' do

      described_class.perform_now
      
    end

    # before do
    #   Setting.set('system_init_done', true)
    # end

    # let!(:organization) { create(:organization, name: 'test') }
    # let!(:admin) { create(:admin) }
    # let!(:user) { create(:customer, organization: organization) }

    # it 'checks if the user is deleted' do
    #   create(:data_privacy_task, deletable: user)
    #   described_class.perform_now
    #   expect { user.reload }.to raise_error(ActiveRecord::RecordNotFound)
    # end

    # it 'checks if the organization is deleted' do
    #   create(:data_privacy_task, deletable: user)
    #   described_class.perform_now
    #   expect(organization.reload).to be_a_kind_of(Organization)
    # end

    # it 'checks if the state is completed' do
    #   task = create(:data_privacy_task, deletable: user)
    #   described_class.perform_now
    #   expect(task.reload.state).to eq('completed')
    # end

    # it 'checks if the user is deleted (delete_organization=true)' do
    #   create(:data_privacy_task, deletable: user, preferences: { delete_organization: 'true' })
    #   described_class.perform_now
    #   expect { user.reload }.to raise_error(ActiveRecord::RecordNotFound)
    # end

    # it 'checks if the organization is deleted (delete_organization=true)' do
    #   create(:data_privacy_task, deletable: user, preferences: { delete_organization: 'true' })
    #   described_class.perform_now
    #   expect { organization.reload }.to raise_error(ActiveRecord::RecordNotFound)
    # end

    # it 'checks creation of activity stream log' do
    #   create(:data_privacy_task, deletable: user, created_by: admin)
    #   travel 15.minutes
    #   described_class.perform_now
    #   expect(admin.activity_stream(20).any? { |entry| entry.type.name == 'completed' }).to be true
    # end
  end
end
