require "rails_helper"

RSpec.describe DossierMailer, type: :mailer do
  let(:to_email) { 'gestionnaire@exemple.gouv.fr' }

  describe '.notify_deletion_to_user' do
    let(:deleted_dossier) { build(:deleted_dossier) }

    subject { described_class.notify_deletion_to_user(deleted_dossier, to_email) }

    it { expect(subject.subject).to eq("Votre dossier n° #{deleted_dossier.dossier_id} a bien été supprimé") }
    it { expect(subject.body).to include("Votre dossier") }
    it { expect(subject.body).to include(deleted_dossier.dossier_id) }
    it { expect(subject.body).to include("a bien été supprimé") }
  end

  describe '.notify_deletion_to_administration' do
    let(:deleted_dossier) { build(:deleted_dossier) }

    subject { described_class.notify_deletion_to_administration(deleted_dossier, to_email) }

    it { expect(subject.subject).to eq("Le dossier n° #{deleted_dossier.dossier_id} a été supprimé à la demande de l'usager") }
    it { expect(subject.body).to include("À la demande de l'usager") }
    it { expect(subject.body).to include(deleted_dossier.dossier_id) }
  end

  describe '.notify_unhide_to_user' do
    let(:dossier) { create(:dossier) }

    subject { described_class.notify_unhide_to_user(dossier) }

    it { expect(subject.subject).to eq("Votre dossier n° #{dossier.id} n'a pas pu être supprimé") }
    it { expect(subject.body).to include(dossier.id) }
    it { expect(subject.body).to include("n'a pas pu être supprimé") }
  end
end
