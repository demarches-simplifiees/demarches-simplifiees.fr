RSpec.describe GestionnaireMailer, type: :mailer do
  describe '#send_dossier' do
    let(:sender) { create(:gestionnaire) }
    let(:recipient) { create(:gestionnaire) }
    let(:dossier) { create(:dossier) }

    subject { described_class.send_dossier(sender, dossier, recipient) }

    it { expect(subject.body).to include('Bonjour') }
  end
end
