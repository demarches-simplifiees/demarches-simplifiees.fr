require "rails_helper"

RSpec.describe AvisMailer, type: :mailer do
  describe '.avis_invitation' do
    let(:avis) { create(:avis) }

    subject { described_class.avis_invitation(avis) }

    it { expect(subject.subject).to eq("Donnez votre avis sur le dossier nº #{avis.dossier.id} (#{avis.dossier.procedure.libelle})") }
    it { expect(subject.body).to have_text("Vous avez été invité par #{avis.claimant.email} à donner votre avis sur le dossier nº #{avis.dossier.id} de la démarche : #{avis.dossier.procedure.libelle}") }
    it { expect(subject.body).to include(avis.introduction) }
    it { expect(subject.body).to include(gestionnaire_avis_url(avis)) }

    context 'when the recipient is not already registered' do
      before do
        avis.email = 'instructeur@email.com'
        avis.gestionnaire = nil
      end

      it { expect(subject.body).to include(sign_up_gestionnaire_avis_url(avis.id, avis.email)) }
    end
  end
end
