# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Manage > Integration > S/MIME', type: :system do

  let(:fixture) { 'smime1@example.com' }

  let!(:certificate) do
    Rails.root.join("spec/fixtures/files/smime/#{fixture}.crt").read
  end
  let!(:private_key) do
    Rails.root.join("spec/fixtures/files/smime/#{fixture}.key").read
  end
  let!(:private_key_secret) do
    Rails.root.join("spec/fixtures/files/smime/#{fixture}.secret").read.strip
  end

  before do
    visit 'system/integration/smime'

    # enable S/MIME
    click 'label[for=setting-switch]'
  end

  context 'when doing basic tests' do
    it 'enabling and adding of public and private key' do

      # add cert
      click '.js-addCertificate'
      fill_in 'Paste Certificate', with: certificate
      click '.js-submit'

      # add private key
      click '.js-addPrivateKey'
      fill_in 'Paste Private Key', with: private_key
      fill_in 'Enter Private Key Secret', with: private_key_secret
      click '.js-submit'

      # check result
      expect(Setting.get('smime_integration')).to be true
      expect(SMIMECertificate.last.fingerprint).to be_present
      expect(SMIMECertificate.last.raw).to be_present
      expect(SMIMECertificate.last.private_key).to be_present
    end

    it 'adding of multiple certificates at once' do
      multiple_certificates = [
        Rails.root.join('spec/fixtures/files/smime/ChainCA.crt').read,
        Rails.root.join('spec/fixtures/files/smime/IntermediateCA.crt').read,
        Rails.root.join('spec/fixtures/files/smime/RootCA.crt').read,
      ].join

      # add cert
      click '.js-addCertificate'
      fill_in 'Paste Certificate', with: multiple_certificates
      click '.js-submit'

      # wait for ajax
      expect(page).to have_text('ChainCA')
      expect(page).to have_text('IntermediateCA')
      expect(page).to have_text('RootCA')
    end
  end

  context 'Adding private keys allows adding certificates #3727' do
    let!(:private_key) do
      Rails.root.join('spec/fixtures/files/smime/issue_3727.key').read
    end

    it 'does add public and private key in one file' do

      # add private key
      click '.js-addPrivateKey'
      fill_in 'Paste Private Key', with: private_key
      click '.js-submit'

      # check result
      expect(Setting.get('smime_integration')).to be true
      expect(SMIMECertificate.last.fingerprint).to eq('db49277070afcfc657bd71d04be4dd7e28f1685a')
      expect(SMIMECertificate.last.raw).to include('CERTIFICATE')
      expect(SMIMECertificate.last.raw).not_to include('PRIVATE')
      expect(SMIMECertificate.last.private_key).to include('PRIVATE')
      expect(SMIMECertificate.last.private_key).not_to include('CERTIFICATE')
    end
  end
end
