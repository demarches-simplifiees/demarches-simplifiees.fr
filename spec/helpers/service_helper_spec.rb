require 'spec_helper'

RSpec.describe ServiceHelper, type: :helper do
  describe '#email_for_reply_to' do
    let(:email) { 'administration@example.fr' }
    let(:service) { create(:service, email: email) }

    subject { email_for_reply_to(service) }

    context 'when the service email is valid' do
      let(:email) { 'contact@prefecture.gouv.fr' }
      it { is_expected.to eq [email, CONTACT_EMAIL] }
    end

    context 'when the service email is invalid' do
      let(:email) { 'ne-pas-repondre' }
      it { is_expected.to be_nil }
    end

    context 'when the service service does not exist' do
      let(:service) { nil }
      it { is_expected.to be_nil }
    end
  end
end
