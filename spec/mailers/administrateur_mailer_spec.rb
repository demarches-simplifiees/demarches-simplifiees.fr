RSpec.describe AdministrateurMailer, type: :mailer do
  let(:procedure) { create(:procedure) }
  let(:admin_email) { 'administrateur@email.fr' }
  describe '.notify_procedure_expires_when_termine_forced' do
    subject { described_class.notify_procedure_expires_when_termine_forced(admin_email, procedure) }
    it { expect(subject.to).to eq([admin_email]) }
    it { expect(subject.subject).to include("La suppression automatique des dossiers a été activée sur la démarche") }
  end
  describe '.activate_before_expiration' do
    let(:user) { create(:user, reset_password_sent_at: 2.days.ago) }
    let(:token) { SecureRandom.hex }

    context 'without SafeMailer configured' do
      subject { described_class.activate_before_expiration(user, token) }
      it { expect(subject[BalancerDeliveryMethod::FORCE_DELIVERY_METHOD_HEADER]&.value).to eq(nil) }
    end

    context 'with SafeMailer configured' do
      let(:forced_delivery_method) { :kikoo }
      before { allow(SafeMailer).to receive(:forced_delivery_method).and_return(forced_delivery_method) }
      subject { described_class.activate_before_expiration(user, token) }
      it { expect(subject[BalancerDeliveryMethod::FORCE_DELIVERY_METHOD_HEADER]&.value).to eq(forced_delivery_method.to_s) }
    end
  end
end
