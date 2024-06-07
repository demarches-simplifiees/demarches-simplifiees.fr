RSpec.describe DossierMailer, type: :mailer do
  let(:to_email) { 'instructeur@exemple.gouv.fr' }

  shared_examples 'a dossier notification' do
    it 'is sent from a no-reply address' do
      expect(subject.from.first).to eq(Mail::Address.new(NO_REPLY_EMAIL).address)
    end

    it 'includes the contact informations in the footer' do
      expect(subject.body).to include('ne pas répondre')
    end
  end

  describe '.notify_new_draft' do
    let(:user) { create(:user) }
    let(:dossier) { create(:dossier, procedure: create(:simple_procedure, :with_auto_archive), user:) }

    subject { described_class.with(dossier:).notify_new_draft }

    it 'includes the correct subject and body content' do
      expect(subject.subject).to include("brouillon")
      expect(subject.subject).to include(dossier.procedure.libelle)
      expect(subject.body).to include(dossier.procedure.libelle)
      expect(subject.body).to include(dossier_url(dossier, host: ENV.fetch("APP_HOST_LEGACY")))
      expect(subject.body).to include("Vous pouvez déposer votre dossier jusqu’au")
      expect(subject.body).to include("heure de")
    end

    it_behaves_like 'a dossier notification'

    context "when user prefers new domain" do
      let(:user) { create(:user, preferred_domain: :demarches_gouv_fr) }

      it 'includes the correct body content and sender email' do
        expect(subject.body).to include(dossier_url(dossier, host: 'demarches.gouv.fr'))
        expect(header_value("From", subject)).to include("ne-pas-repondre@demarches.gouv.fr")
      end
    end
  end

  describe '.notify_new_answer with dossier brouillon' do
    let(:service) { build(:service) }
    let(:procedure) { create(:simple_procedure, service: service) }
    let(:dossier) { create(:dossier, procedure: procedure) }
    let(:commentaire) { create(:commentaire, dossier: dossier) }
    subject { described_class.with(commentaire: commentaire).notify_new_answer }

    it 'checks email subject and body for correct inclusions and exclusions' do
      expect(subject.subject).to include("Nouveau message")
      expect(subject.subject).to include(dossier.id.to_s)
      expect(subject.body).to include(dossier.procedure.service.email)
      expect(subject.body).not_to include(messagerie_dossier_url(dossier, host: ENV.fetch("APP_HOST_LEGACY")))
    end

    it_behaves_like 'a dossier notification'

    context 'when there is no associated service' do
      let(:service) { nil }
      it { expect { subject }.not_to raise_error }
    end
  end

  describe '.notify_new_answer with dossier en construction' do
    let(:dossier) { create(:dossier, :en_construction, procedure: create(:simple_procedure)) }
    let(:commentaire) { create(:commentaire, dossier: dossier) }

    subject { described_class.with(commentaire: commentaire).notify_new_answer }

    it 'checks email subject and body for correct inclusions' do
      expect(subject.subject).to include("Nouveau message")
      expect(subject.subject).to include(dossier.id.to_s)
      expect(subject.body).to include(messagerie_dossier_url(dossier, host: ENV.fetch("APP_HOST_LEGACY")))
    end

    it_behaves_like 'a dossier notification'
  end

  describe '.notify_new_answer with commentaire discarded' do
    let(:dossier) { create(:dossier, procedure: create(:simple_procedure)) }
    let(:commentaire) { create(:commentaire, dossier: dossier, discarded_at: 2.minutes.ago) }

    subject { described_class.with(commentaire: commentaire).notify_new_answer }

    it { expect(subject.perform_deliveries).to be_falsy }
  end

  def notify_deletion_to_administration(deleted_dossier, to_email)
    @subject = default_i18n_subject(dossier_id: deleted_dossier.dossier_id)
    @deleted_dossier = deleted_dossier

    mail(to: to_email, subject: @subject)
  end

  describe '.notify_deletion_to_administration' do
    let(:deleted_dossier) { build(:deleted_dossier) }

    subject { described_class.notify_deletion_to_administration(deleted_dossier, to_email) }

    it 'verifies subject and body content for deletion notification' do
      expect(subject.subject).to eq("Le dossier nº #{deleted_dossier.dossier_id} a été supprimé à la demande de l’usager")
      expect(subject.body).to include("À la demande de l’usager")
      expect(subject.body).to include(deleted_dossier.dossier_id)
      expect(subject.body).to include(deleted_dossier.procedure.libelle)
    end
  end

  describe '.notify_brouillon_near_deletion' do
    let(:dossier) { create(:dossier) }

    subject { described_class.notify_brouillon_near_deletion([dossier], dossier.user.email) }

    it 'checks email body for correct inclusions regarding brouillon nearing deletion' do
      expect(subject.body).to include("n° #{dossier.id} ")
      expect(subject.body).to include(dossier.procedure.libelle)
    end
  end

  describe '.notify_brouillon_deletion' do
    let(:dossier) { create(:dossier) }

    subject { described_class.notify_brouillon_deletion([dossier.hash_for_deletion_mail], dossier.user.email) }

    it 'verifies subject and body content for brouillon deletion notification' do
      expect(subject.subject).to eq("Un dossier en brouillon a été supprimé automatiquement")
      expect(subject.body).to include("n° #{dossier.id} (#{dossier.procedure.libelle})")
    end
  end

  describe '.notify_automatic_deletion_to_user' do
    let(:deleted_dossier) { create(:deleted_dossier, dossier: dossier, reason: :expired) }

    describe 'en_construction' do
      let(:dossier) { create(:dossier, :en_construction) }

      subject { described_class.notify_automatic_deletion_to_user([deleted_dossier], dossier.user.email) }

      it 'checks email subject, to, and body for correct inclusions and exclusions for en_construction status' do
        expect(subject.to).to eq([dossier.user.email])
        expect(subject.subject).to eq("Un dossier a été supprimé automatiquement de votre compte")
        expect(subject.body).to include("N° #{dossier.id} ")
        expect(subject.body).to include(dossier.procedure.libelle)
        expect(subject.body).to include("nous nous excusons de la gêne occasionnée")
      end
    end

    describe 'termine' do
      let(:dossier) { create(:dossier, :accepte) }

      subject { described_class.notify_automatic_deletion_to_user([deleted_dossier], dossier.user.email) }

      it 'checks email subject, to, and body for correct inclusions and exclusions for termine status' do
        expect(subject.to).to eq([dossier.user.email])
        expect(subject.subject).to eq("Un dossier a été supprimé automatiquement de votre compte")
        expect(subject.body).to include("N° #{dossier.id} ")
        expect(subject.body).to include(dossier.procedure.libelle)
        expect(subject.body).not_to include("nous nous excusons de la gêne occasionnée")
      end
    end
  end

  describe '.notify_automatic_deletion_to_administration' do
    let(:dossier) { create(:dossier, :en_construction) }
    let(:deleted_dossier) { create(:deleted_dossier, dossier: dossier, reason: :expired) }

    subject { described_class.notify_automatic_deletion_to_administration([deleted_dossier], dossier.user.email) }

    it 'verifies subject and body content for automatic deletion notification' do
      expect(subject.subject).to eq("Un dossier a été supprimé automatiquement")
      expect(subject.body).to include("n° #{dossier.id} (#{dossier.procedure.libelle})")
    end
  end

  describe '.notify_near_deletion_to_administration' do
    describe 'en_construction' do
      let(:dossier) { create(:dossier, :en_construction) }

      subject { described_class.notify_near_deletion_to_administration([dossier], dossier.user.email) }

      it 'checks email subject and body for correct inclusions for en_construction status' do
        expect(subject.subject).to eq("Un dossier en construction va bientôt être supprimé")
        expect(subject.body).to include("N° #{dossier.id} ")
        expect(subject.body).to include(dossier.procedure.libelle)
        expect(subject.body).to include("PDF")
        expect(subject.body).to include("Vous avez <b>14 jours</b> pour commencer l’instruction du dossier.")
      end
    end

    describe 'termine' do
      let(:dossier) { create(:dossier, :accepte) }

      subject { described_class.notify_near_deletion_to_administration([dossier], dossier.user.email) }

      it 'verifies subject and body content for near deletion notification of completed cases' do
        expect(subject.subject).to eq("Un dossier dont le traitement est terminé va bientôt être supprimé")
        expect(subject.body).to include("N° #{dossier.id} ")
        expect(subject.body).to include(dossier.procedure.libelle)
      end
    end
  end

  describe '.notify_near_deletion_to_user' do
    describe 'en_construction' do
      let(:dossier) { create(:dossier, :en_construction) }

      subject { described_class.notify_near_deletion_to_user([dossier], dossier.user.email) }

      it 'verifies email subject, to, and body for correct inclusions for en_construction status' do
        expect(subject.to).to eq([dossier.user.email])
        expect(subject.subject).to eq("Un dossier en construction va bientôt être supprimé")
        expect(subject.body).to include("N° #{dossier.id} ")
        expect(subject.body).to include(dossier.procedure.libelle)
        expect(subject.body).to include("Votre compte reste activé")
        expect(subject.body).to include("Si vous souhaitez conserver votre dossier plus longtemps, vous pouvez <b>prolonger sa durée de conservation</b> dans l’interface.")
      end
    end

    describe 'termine' do
      let(:dossier) { create(:dossier, :accepte) }

      subject { described_class.notify_near_deletion_to_user([dossier], dossier.user.email) }

      it 'checks email subject, to, and body for correct inclusions for termine status' do
        expect(subject.to).to eq([dossier.user.email])
        expect(subject.subject).to eq("Un dossier dont le traitement est terminé va bientôt être supprimé")
        expect(subject.body).to include("N° #{dossier.id} ")
        expect(subject.body).to include(dossier.procedure.libelle)
        expect(subject.body).to include("Votre compte reste activé")
        expect(subject.body).to include("PDF")
      end
    end

    describe 'multiple termines' do
      let(:dossiers) { create_list(:dossier, 3, :accepte) }

      subject { described_class.notify_near_deletion_to_user(dossiers, dossiers[0].user.email) }

      it 'verifies email subject and body contain correct dossier numbers for multiple termine status' do
        expect(subject.subject).to eq("Des dossiers dont le traitement est terminé vont bientôt être supprimés")
        dossiers.each do |dossier|
          expect(subject.body).to include("N° #{dossier.id} ")
        end
      end
    end
  end

  describe '.notify_groupe_instructeur_changed_to_instructeur' do
    let(:dossier) { create(:dossier) }
    let(:instructeur) { create(:instructeur) }

    subject { described_class.notify_groupe_instructeur_changed(instructeur, dossier) }

    it 'verifies subject and body content for groupe instructeur change notification' do
      expect(subject.subject).to eq("Le dossier nº #{dossier.id} a changé de groupe d’instructeurs")
      expect(subject.body).to include("n° #{dossier.id}")
      expect(subject.body).to include(dossier.procedure.libelle)
      expect(subject.body).to include("Suite à cette modification, vous ne suivez plus ce dossier.")
    end
  end

  describe '.notify_pending_correction' do
    let(:procedure) { create(:procedure) }
    let(:dossier) { create(:dossier, :en_construction, procedure:, sva_svr_decision_on:) }
    let(:sva_svr_decision_on) { nil }
    let(:reason) { :incorrect }
    let(:commentaire) { create(:commentaire, dossier:) }

    subject {
      dossier.flag_as_pending_correction!(commentaire, reason)
      described_class.with(commentaire:).notify_pending_correction
    }

    context 'reason is incorrect' do
      it 'checks email subject and body for corrections without Silence Vaut Accord' do
        expect(subject.subject).to eq("Vous devez corriger votre dossier nº #{dossier.id} « #{dossier.procedure.libelle} »")
        expect(subject.body).to include("apporter des corrections")
        expect(subject.body).not_to include("Silence")
      end
    end

    context 'sva with reason is incorrect' do
      let(:sva_svr_decision_on) { Date.tomorrow }
      let(:procedure) { create(:procedure, :sva) }

      it 'includes Silence Vaut Accord and mentions suspension for incorrect reason' do
        expect(subject.subject).to eq("Vous devez corriger votre dossier nº #{dossier.id} « #{dossier.procedure.libelle} »")
        expect(subject.body).to include("apporter des corrections")
        expect(subject.body).to include("Silence Vaut Accord")
        expect(subject.body).to include("suspendu")
      end
    end

    context 'sva with reason is incomplete' do
      let(:sva_svr_decision_on) { Date.tomorrow }
      let(:reason) { :incomplete }
      let(:procedure) { create(:procedure, :sva) }

      it 'mentions the need to complete the dossier and includes Silence Vaut Accord with reset message' do
        expect(subject.body).to include("compléter")
        expect(subject.body).to include("Silence Vaut Accord")
        expect(subject.body).to include("réinitialisé")
      end
    end

    context 'svr with reason is incomplete' do
      let(:sva_svr_decision_on) { Date.tomorrow }
      let(:reason) { :incomplete }
      let(:procedure) { create(:procedure, :svr) }

      it 'mentions the need to complete the dossier and includes Silence Vaut Rejet with reset message' do
        expect(subject.body).to include("compléter")
        expect(subject.body).to include("Silence Vaut Rejet")
        expect(subject.body).to include("réinitialisé")
      end
    end
  end

  describe 'notify_transfer' do
    let(:user) { create(:user) }
    let(:procedure) { create(:procedure) }
    let(:dossier_transfer) { create(:dossier_transfer) }
    let!(:dossier) { create(:dossier, user: user, transfer: dossier_transfer, procedure: procedure) }

    subject { described_class.with(dossier_transfer: dossier_transfer).notify_transfer }

    context 'when it is a transfer of one dossier' do
      it 'includes relevant details about the single dossier transfer request' do
        expect(subject.subject).to include("Vous avez une demande de transfert en attente.")
        expect(subject.body).to include("#{user.email} vous adresse une demande de transfert pour le dossier n° #{dossier.id} sur la démarche")
        expect(subject.body).to include(procedure.libelle.to_s)
      end
    end

    context 'when recipient has preferred domain' do
      let(:dossier_transfer) { create(:dossier_transfer, email: create(:user, preferred_domain: :demarches_gouv_fr).email) }
      it 'includes a link with the preferred domain in the email body' do
        expect(subject.body).to include(dossiers_url(statut: "dossiers-transferes", host: 'demarches.gouv.fr'))
      end
    end

    context 'when it is a transfer of multiple dossiers' do
      let!(:dossier2) { create(:dossier, user: user, transfer: dossier_transfer, procedure: procedure) }
      it 'includes a summary of multiple dossiers transfer request' do
        expect(subject.subject).to include("Vous avez une demande de transfert en attente.")
        expect(subject.body).to include("#{user.email} vous adresse une demande de transfert pour 2 dossiers.")
      end
    end

    context 'when it is a transfer of one dossier from super admin' do
      before do
        dossier_transfer.update!(from_support: true)
      end

      it 'includes details indicating the transfer request is from support' do
        expect(subject.subject).to include("Vous avez une demande de transfert en attente.")
        expect(subject.body).to include("Le support technique vous adresse une demande de transfert")
      end
    end

    context 'when dossiers have been dissociated from transfer' do
      before do
        dossier.update!(transfer: nil)
        dossier_transfer.reload
      end

      it 'does not send an email' do
        expect { subject.perform_now }.not_to raise_error
      end
    end
  end
end
