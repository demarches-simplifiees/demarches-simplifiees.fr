require "rails_helper"

RSpec.describe DossierMailer, type: :mailer do
  let(:to_email) { 'instructeur@exemple.gouv.fr' }

  shared_examples 'a dossier notification' do
    it 'includes the contact informations in the footer' do
      expect(subject.body).to include('ne pas répondre')
    end
  end

  describe '.notify_new_draft' do
    let(:dossier) { create(:dossier, procedure: build(:simple_procedure)) }

    subject { described_class.notify_new_draft(dossier) }

    it { expect(subject.subject).to include("brouillon") }
    it { expect(subject.subject).to include(dossier.procedure.libelle) }
    it { expect(subject.body).to include(dossier.procedure.libelle) }
    it { expect(subject.body).to include(dossier_url(dossier)) }

    it_behaves_like 'a dossier notification'
  end

  describe '.notify_new_answer' do
    let(:dossier) { create(:dossier, procedure: build(:simple_procedure)) }

    subject { described_class.notify_new_answer(dossier) }

    it { expect(subject.subject).to include("Nouveau message") }
    it { expect(subject.subject).to include(dossier.id.to_s) }
    it { expect(subject.body).to include(messagerie_dossier_url(dossier)) }

    it_behaves_like 'a dossier notification'
  end

  describe '.notify_deletion_to_user' do
    let(:deleted_dossier) { build(:deleted_dossier) }

    subject { described_class.notify_deletion_to_user(deleted_dossier, to_email) }

    it { expect(subject.subject).to eq("Votre dossier nº #{deleted_dossier.dossier_id} a bien été supprimé") }
    it { expect(subject.body).to include("Votre dossier") }
    it { expect(subject.body).to include(deleted_dossier.dossier_id) }
    it { expect(subject.body).to include("a bien été supprimé") }
    it { expect(subject.body).to include(deleted_dossier.procedure.libelle) }
  end

  describe '.notify_deletion_to_administration' do
    let(:deleted_dossier) { build(:deleted_dossier) }

    subject { described_class.notify_deletion_to_administration(deleted_dossier, to_email) }

    it { expect(subject.subject).to eq("Le dossier nº #{deleted_dossier.dossier_id} a été supprimé à la demande de l'usager") }
    it { expect(subject.body).to include("À la demande de l'usager") }
    it { expect(subject.body).to include(deleted_dossier.dossier_id) }
    it { expect(subject.body).to include(deleted_dossier.procedure.libelle) }
  end

  describe '.notify_unhide_to_user' do
    let(:dossier) { create(:dossier) }

    subject { described_class.notify_unhide_to_user(dossier) }

    it { expect(subject.subject).to eq("Votre dossier nº #{dossier.id} n'a pas pu être supprimé") }
    it { expect(subject.body).to include(dossier.id) }
    it { expect(subject.body).to include("n'a pas pu être supprimé") }
    it { expect(subject.body).to include(dossier.procedure.libelle) }
  end

  describe '.notify_auto_deletion_to' do
    let(:dossier) { create(:dossier) }
    let(:dossier2) { create(:dossier) }

    subject { described_class.notify_auto_deletion_to([dossier, dossier2], dossier.user.email) }

    it { expect(subject.subject).to eq("Des dossiers ont été supprimés automatiquement") }
    it { expect(subject.body).to include("dossier n°#{ dossier.id} qui concerne la procedure '#{dossier.procedure.libelle}'")}
    it { expect(subject.body).to include("dossier n°#{ dossier2.id} qui concerne la procedure '#{dossier2.procedure.libelle}'")}
  end

  describe '.notify_excuse_deletion_to_user' do
    let(:dossier) { create(:dossier) }

    subject { described_class.notify_excuse_deletion_to_user([dossier], dossier.user.email) }

    it { expect(subject.subject).to eq("Des dossiers ont été supprimés automatiquement") }
    it { expect(subject.body).to include("dossier n°#{ dossier.id} qui concerne la procedure '#{dossier.procedure.libelle}'")}
    it { expect(subject.body).to include("Nous nous excusons de la gène occasionnée.") }
  end

  describe '.notify_near_deletion' do
    let!(:dossier) { create(:dossier) }
    subject { described_class.notify_near_deletion(["#{ dossier.id} avec du texte","texte"], dossier.user.email) }

    it { expect(subject.subject).to eq("Des dossiers vont bientôt être supprimés") }
    it { expect(subject.body).to include("n°#{ dossier.id} avec du texte")}
    it { expect(subject.body).to include("n°texte")}
  end

end
