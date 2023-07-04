RSpec.describe DeviseUserMailer, type: :mailer do
  let(:user) { create(:user) }
  let(:token) { SecureRandom.hex }
  describe '.confirmation_instructions' do
    context 'without SafeMailer configured' do
      subject { described_class.confirmation_instructions(user, token, opts = {}) }
      it { expect(subject[BalancerDeliveryMethod::FORCE_DELIVERY_METHOD_HEADER]&.value).to eq(nil) }
    end
    context 'with SafeMailer configured' do
      let(:forced_delivery_method) { :kikoo }
      before { allow(SafeMailer).to receive(:forced_delivery_method).and_return(forced_delivery_method) }
      subject { described_class.confirmation_instructions(user, token, opts = {}) }
      it { expect(subject[BalancerDeliveryMethod::FORCE_DELIVERY_METHOD_HEADER]&.value).to eq(forced_delivery_method.to_s) }
    end
  end
end
