require "rails_helper"

RSpec.describe DossierMailer, type: :mailer do
  let(:to_email) { 'gestionnaire@exemple.gouv.fr' }

  describe '.notify_new_draft' do
    let(:dossier) { create(:dossier, procedure: build(:simple_procedure)) }

    subject { described_class.notify_new_draft(dossier) }

    it { expect(subject.subject).to include("brouillon") }
    it { expect(subject.subject).to include(dossier.procedure.libelle) }
    it { expect(subject.body).to include(dossier.procedure.libelle) }
    it { expect(subject.body).to include(dossier_url(dossier)) }
  end

  describe '.notify_new_answer' do
    let(:dossier) { create(:dossier, procedure: build(:simple_procedure)) }

    subject { described_class.notify_new_answer(dossier) }

    it { expect(subject.subject).to include("Nouveau message") }
    it { expect(subject.subject).to include(dossier.id.to_s) }
    it { expect(subject.body).to include(messagerie_dossier_url(dossier)) }
  end

  describe '.notify_inbound_error' do
    subject { described_class.notify_inbound_error('user@ds.fr') }

    it { expect(subject.subject).to include("Nous n’avons pas pu enregistrer votre réponse") }
    it { expect(subject.body).to include(dossiers_url) }
  end

  describe '.notify_deletion_to_user' do
    let(:deleted_dossier) { build(:deleted_dossier) }

    subject { described_class.notify_deletion_to_user(deleted_dossier, to_email) }

    it { expect(subject.subject).to eq("Votre dossier n° #{deleted_dossier.dossier_id} a bien été supprimé") }
    it { expect(subject.body).to include("Votre dossier") }
    it { expect(subject.body).to include(deleted_dossier.dossier_id) }
    it { expect(subject.body).to include("a bien été supprimé") }
    it { expect(subject.body).to include(deleted_dossier.procedure.libelle) }
  end

  describe '.notify_deletion_to_administration' do
    let(:deleted_dossier) { build(:deleted_dossier) }

    subject { described_class.notify_deletion_to_administration(deleted_dossier, to_email) }

    it { expect(subject.subject).to eq("Le dossier n° #{deleted_dossier.dossier_id} a été supprimé à la demande de l'usager") }
    it { expect(subject.body).to include("À la demande de l'usager") }
    it { expect(subject.body).to include(deleted_dossier.dossier_id) }
    it { expect(subject.body).to include(deleted_dossier.procedure.libelle) }
  end

  describe '.notify_unhide_to_user' do
    let(:dossier) { create(:dossier) }

    subject { described_class.notify_unhide_to_user(dossier) }

    it { expect(subject.subject).to eq("Votre dossier n° #{dossier.id} n'a pas pu être supprimé") }
    it { expect(subject.body).to include(dossier.id) }
    it { expect(subject.body).to include("n'a pas pu être supprimé") }
    it { expect(subject.body).to include(dossier.procedure.libelle) }
  end
end
