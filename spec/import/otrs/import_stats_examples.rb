RSpec.shared_examples 'Import::OTRS::ImportStats' do
  it 'responds to current_state' do
    expect(described_class).to respond_to('current_state')
  end
end
