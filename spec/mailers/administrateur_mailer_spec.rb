RSpec.describe AdministrateurMailer, type: :mailer do
  let(:procedure) { create(:procedure) }
  let(:admin_email) { 'administrateur@email.fr' }
  describe '.notify_procedure_expires_when_termine_forced' do
    subject { described_class.notify_procedure_expires_when_termine_forced(admin_email, procedure) }
    it { expect(subject.to).to eq([admin_email]) }
    it { expect(subject.subject).to include("La suppression automatique des dossiers a été activée sur la démarche") }
  end
end
