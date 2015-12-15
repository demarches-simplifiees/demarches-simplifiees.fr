require "rails_helper"

RSpec.describe NotificationMailer, type: :mailer do
  describe ".new_answer" do
    let(:user) { create(:user) }
    let(:dossier) { create(:dossier, :with_procedure, user: user) }

    subject(:subject) { described_class.new_answer(dossier) }

    it { expect(subject.body).to match('Un nouveau commentaire est disponible dans votre espace TPS.') }
    it { expect(subject.body).to include("Pour le consulter, merci de vous rendre sur #{users_dossiers_url(id: dossier.id)}") }
    it { expect(subject.subject).to eq("Nouveau commentaire pour votre dossier TPS N°#{dossier.id}") }
  end

  describe ".dossier_validated" do
    let(:user) { create(:user) }
    let(:dossier) { create(:dossier, :with_procedure, user: user) }

    subject(:subject) { described_class.dossier_validated(dossier) }

    it { expect(subject.body).to match("Votre dossier N°#{dossier.id} a été validé par votre gestionnaire.") }
    it { expect(subject.body).to include("Afin de finaliser son dépot, merci de vous rendre sur #{users_dossiers_url(id: dossier.id)}") }
    it { expect(subject.subject).to eq("Votre dossier TPS N°#{dossier.id} a été validé") }
  end
end
