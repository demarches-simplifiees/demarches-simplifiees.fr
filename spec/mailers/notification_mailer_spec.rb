require "rails_helper"

RSpec.describe NotificationMailer, type: :mailer do
  describe ".new_answer" do
    let(:user) { create(:user) }
    let(:dossier) { create(:dossier, user: user) }

    subject(:subject) { described_class.new_answer(dossier) }

    it { expect(subject.body).to match('Un nouveau commentaire est disponible dans votre espace TPS.') }
    it { expect(subject.body).to include("Pour le consulter, merci de vous rendre sur #{users_dossier_recapitulatif_url(dossier_id: dossier.id)}") }
    it { expect(subject.subject).to eq("Nouveau commentaire pour votre dossier TPS N°#{dossier.id}") }
  end

  describe ".dossier_validated" do
    let(:user) { create(:user) }
    let(:dossier) { create(:dossier, user: user) }

    subject(:subject) { described_class.dossier_validated(dossier) }

    it { expect(subject.body).to match("Votre dossier N°#{dossier.id} a été validé par votre accompagnateur.") }
    it { expect(subject.body).to include("Afin de finaliser son dépot, merci de vous rendre sur #{users_dossier_recapitulatif_url(dossier_id: dossier.id)}") }
    it { expect(subject.subject).to eq("Votre dossier TPS N°#{dossier.id} a été validé") }
  end

  describe ".dossier_submitted" do
    let(:user) { create(:user) }
    let(:dossier) { create(:dossier, user: user) }

    subject(:subject) { described_class.dossier_submitted(dossier) }

    it { expect(subject.body).to match("Nous vous confirmons que votre dossier N°#{dossier.id} a été déposé") }
    it { expect(subject.body).to match("aurpès de #{dossier.procedure.organisation} avec succès") }
    it { expect(subject.body).to match("ce jour à #{dossier.updated_at}.") }
    it { expect(subject.subject).to eq("Votre dossier TPS N°#{dossier.id} a été déposé") }
  end
end
