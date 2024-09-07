describe Instructeurs::DossiersController, type: :controller do
  render_views

  let(:instructeur) { create(:instructeur) }
  let(:administrateur) { create(:administrateur) }
  let(:administration) { create(:administration) }
  let(:instructeurs) { [instructeur] }
  let(:procedure) { create(:procedure, :published, :for_individual, instructeurs: instructeurs) }
  let(:procedure_accuse_lecture) { create(:procedure, :published, :for_individual, :accuse_lecture, instructeurs: instructeurs) }
  let(:dossier) { create(:dossier, :en_construction, :with_individual, procedure: procedure) }
  let(:dossier_accuse_lecture) { create(:dossier, :en_construction, :with_individual, procedure: procedure_accuse_lecture) }
  let(:dossier_for_tiers) { create(:dossier, :en_construction, :for_tiers_with_notification, procedure: procedure) }
  let(:dossier_for_tiers_without_notif) { create(:dossier, :en_construction, :for_tiers_without_notification, procedure: procedure) }
  let(:fake_justificatif) { fixture_file_upload('spec/fixtures/files/piece_justificative_0.pdf', 'application/pdf') }

  before { sign_in(instructeur.user) }

  describe '#send_to_instructeurs' do
    let(:mail) { double("mail") }

    before do
      allow(mail).to receive(:deliver_later)

      allow(InstructeurMailer)
        .to receive(:send_dossier)
        .with(instructeur, dossier, recipient)
        .and_return(mail)

      post(
        :send_to_instructeurs,
        params: {
          recipients: [recipient.id].to_json,
          procedure_id: procedure.id,
          dossier_id: dossier.id
        }
      )
    end

    context 'when the recipient belongs to the dossier groupe instructeur' do
      let(:recipient) { instructeur }

      it do
        expect(InstructeurMailer).to have_received(:send_dossier)
        expect(response).to redirect_to(personnes_impliquees_instructeur_dossier_url)
        expect(recipient.followed_dossiers).to include(dossier)
      end
    end

    context 'when the recipient is random' do
      let(:recipient) { create(:instructeur) }

      it do
        expect(InstructeurMailer).not_to have_received(:send_dossier)
        expect(response).to redirect_to(personnes_impliquees_instructeur_dossier_url)
        expect(recipient.followed_dossiers).not_to include(dossier)
      end
    end
  end

  describe '#follow' do
    let(:batch_operation) {}
    before do
      batch_operation
      patch :follow, params: { procedure_id: procedure.id, dossier_id: dossier.id }
    end

    it { expect(instructeur.followed_dossiers).to match([dossier]) }
    it { expect(flash.notice).to eq('Dossier suivi') }
    it { expect(response).to redirect_to(instructeur_procedure_path(dossier.procedure)) }

    context 'with dossier in batch_operation' do
      let(:batch_operation) { create(:batch_operation, operation: :archiver, dossiers: [dossier], instructeur: instructeur) }
      it { expect(instructeur.followed_dossiers).to eq([]) }
      it { expect(response).to redirect_to(instructeur_dossier_path(dossier.procedure, dossier)) }
      it { expect(flash.alert).to eq("Votre action n'a pas été effectuée, ce dossier fait parti d'un traitement de masse.") }
    end
  end

  describe '#unfollow' do
    let(:batch_operation) {}
    before do
      batch_operation
      instructeur.followed_dossiers << dossier
      patch :unfollow, params: { procedure_id: procedure.id, dossier_id: dossier.id }
      instructeur.reload
    end

    it { expect(instructeur.followed_dossiers).to match([]) }
    it { expect(flash.notice).to eq("Vous ne suivez plus le dossier nº #{dossier.id}") }
    it { expect(response).to redirect_to(instructeur_procedure_path(dossier.procedure)) }
    context 'with dossier in batch_operation' do
      let(:batch_operation) { create(:batch_operation, operation: :archiver, dossiers: [dossier], instructeur: instructeur) }
      it { expect(instructeur.followed_dossiers).to eq([dossier]) }
      it { expect(response).to redirect_to(instructeur_dossier_path(dossier.procedure, dossier)) }
      it { expect(flash.alert).to eq("Votre action n'a pas été effectuée, ce dossier fait parti d'un traitement de masse.") }
    end
  end

  describe '#archive' do
    let(:batch_operation) {}
    before do
      batch_operation
      patch :archive, params: { procedure_id: procedure.id, dossier_id: dossier.id }
      dossier.reload
      instructeur.follow(dossier)
    end

    it { expect(dossier.archived).to eq(true) }
    it { expect(response).to redirect_to(instructeur_procedure_path(dossier.procedure)) }

    context 'with dossier in batch_operation' do
      let(:batch_operation) { create(:batch_operation, operation: :archiver, dossiers: [dossier], instructeur: instructeur) }
      it { expect(dossier.archived).to eq(false) }
      it { expect(response).to redirect_to(instructeur_dossier_path(dossier.procedure, dossier)) }
      it { expect(flash.alert).to eq("Votre action n'a pas été effectuée, ce dossier fait parti d'un traitement de masse.") }
    end
  end

  describe '#unarchive' do
    let(:batch_operation) {}
    before do
      batch_operation
      dossier.update(archived: true)
      patch :unarchive, params: { procedure_id: procedure.id, dossier_id: dossier.id }
    end

    it { expect(dossier.reload.archived).to eq(false) }
    it { expect(response).to redirect_to(instructeur_procedure_path(dossier.procedure)) }

    context 'with dossier in batch_operation' do
      let!(:batch_operation) { create(:batch_operation, operation: :archiver, dossiers: [dossier], instructeur: instructeur) }
      it { expect(dossier.reload.archived).to eq(true) }
      it { expect(response).to redirect_to(instructeur_dossier_path(dossier.procedure, dossier)) }
      it { expect(flash.alert).to eq("Votre action n'a pas été effectuée, ce dossier fait parti d'un traitement de masse.") }
    end
  end

  describe '#passer_en_instruction' do
    let(:dossier) { create(:dossier, :en_construction, procedure: procedure) }
    let(:batch_operation) {}
    before do
      batch_operation
      sign_in(instructeur.user)
      post :passer_en_instruction, params: { procedure_id: procedure.id, dossier_id: dossier.id }, format: :turbo_stream
    end

    it { expect(dossier.reload.state).to eq(Dossier.states.fetch(:en_instruction)) }
    it { expect(instructeur.follow?(dossier)).to be true }
    it { expect(response).to have_http_status(:ok) }
    it { expect(response.body).to include('header-top') }

    context 'when the dossier has already been put en_instruction' do
      let(:dossier) { create(:dossier, :en_instruction, procedure: procedure) }

      it 'warns about the error' do
        expect(dossier.reload.state).to eq(Dossier.states.fetch(:en_instruction))
        expect(response).to have_http_status(:ok)
        expect(response.body).to include('Le dossier est déjà en instruction.')
      end
    end

    context 'when the dossier has already been closed' do
      let(:dossier) { create(:dossier, :accepte, procedure: procedure) }

      it 'doesn’t change the dossier state' do
        expect(dossier.reload.state).to eq(Dossier.states.fetch(:accepte))
      end

      it 'warns about the error' do
        expect(response).to have_http_status(:ok)
        expect(response.body).to include('Le dossier est en ce moment accepté : il n’est pas possible de le passer en instruction.')
      end
    end

    context 'with dossier in batch_operation' do
      let(:batch_operation) { create(:batch_operation, operation: :archiver, dossiers: [dossier], instructeur: instructeur) }

      it { expect(response).to redirect_to(instructeur_dossier_path(dossier.procedure, dossier)) }
      it { expect(flash.alert).to eq("Votre action n'a pas été effectuée, ce dossier fait parti d'un traitement de masse.") }
    end
  end

  describe '#repasser_en_construction' do
    let(:dossier) { create(:dossier, :en_instruction, procedure: procedure) }
    let(:batch_operation) {}
    before do
      batch_operation
      sign_in(instructeur.user)
      post :repasser_en_construction,
        params: { procedure_id: procedure.id, dossier_id: dossier.id },
        format: :turbo_stream
    end

    it { expect(dossier.reload.state).to eq(Dossier.states.fetch(:en_construction)) }
    it { expect(response).to have_http_status(:ok) }
    it { expect(response.body).to include('header-top') }

    context 'when the dossier has already been put en_construction' do
      let(:dossier) { create(:dossier, :en_construction, procedure: procedure) }

      it 'warns about the error' do
        expect(dossier.reload.state).to eq(Dossier.states.fetch(:en_construction))
        expect(response).to have_http_status(:ok)
        expect(response.body).to include('Le dossier est déjà en construction.')
      end
    end

    context 'with dossier in batch_operation' do
      let(:batch_operation) { create(:batch_operation, operation: :archiver, dossiers: [dossier], instructeur: instructeur) }
      it { expect(dossier.reload.state).to eq('en_instruction') }
      it { expect(response).to redirect_to(instructeur_dossier_path(dossier.procedure, dossier)) }
      it { expect(flash.alert).to eq("Votre action n'a pas été effectuée, ce dossier fait parti d'un traitement de masse.") }
    end
  end

  describe '#repasser_en_instruction' do
    let(:dossier) { create(:dossier, :refuse, procedure: procedure) }
    let(:batch_operation) {}
    let(:current_user) { instructeur.user }

    before do
      sign_in current_user
      batch_operation
      post :repasser_en_instruction,
      params: { procedure_id: procedure.id, dossier_id: dossier.id },
      format: :turbo_stream
    end

    context 'when the dossier is refuse' do
      it { expect(dossier.reload.state).to eq(Dossier.states.fetch(:en_instruction)) }
      it { expect(response).to have_http_status(:ok) }
      it { expect(response.body).to include('header-top') }
    end

    context 'when the dossier has already been put en_instruction' do
      let(:dossier) { create(:dossier, :en_instruction, procedure: procedure) }

      it 'warns about the error' do
        expect(dossier.reload.state).to eq(Dossier.states.fetch(:en_instruction))
        expect(response).to have_http_status(:ok)
        expect(response.body).to include('Le dossier est déjà en instruction.')
      end
    end

    context 'when the dossier is accepte' do
      let(:dossier) { create(:dossier, :accepte, procedure: procedure) }

      it 'it is possible to go back to en_instruction as instructeur' do
        expect(dossier.reload.state).to eq(Dossier.states.fetch(:en_instruction))
        expect(response).to have_http_status(:ok)
      end
    end

    context 'when the dossier is done and the user delete it' do
      let!(:dossier) { create(:dossier, :accepte, procedure: procedure, user: current_user, hidden_by_user_at: Time.zone.now) }

      it 'reveals the dossier' do
        expect(dossier.reload.state).to eq(Dossier.states.fetch(:en_instruction))
        expect(dossier.reload.hidden_by_user_at).to be_nil
      end
    end

    context 'with dossier in batch_operation' do
      let(:batch_operation) { create(:batch_operation, operation: :archiver, dossiers: [dossier], instructeur: instructeur) }
      it { expect(dossier.reload.state).to eq('refuse') }
      it { expect(response).to redirect_to(instructeur_dossier_path(dossier.procedure, dossier)) }
      it { expect(flash.alert).to eq("Votre action n'a pas été effectuée, ce dossier fait parti d'un traitement de masse.") }
    end
  end

  describe '#terminer' do
    context "with refuser" do
      before do
        dossier.passer_en_instruction!(instructeur: instructeur)
        sign_in(instructeur.user)
      end

      context 'simple refusal' do
        subject { post :terminer, params: { process_action: "refuser", procedure_id: procedure.id, dossier_id: dossier.id }, format: :turbo_stream }

        it 'change state to refuse' do
          subject

          dossier.reload
          expect(dossier.state).to eq(Dossier.states.fetch(:refuse))
          expect(dossier.justificatif_motivation).to_not be_attached
        end

        it 'Notification email is sent' do
          expect(NotificationMailer).to receive(:send_refuse_notification)
            .with(dossier).and_return(NotificationMailer)
          expect(NotificationMailer).to receive(:deliver_later)

          subject
        end

        it 'creates a commentaire' do
          expect { subject }.to change { Commentaire.count }.by(1)
        end
      end

      context 'refusal with a justificatif' do
        subject { post :terminer, params: { process_action: "refuser", procedure_id: procedure.id, dossier_id: dossier.id, dossier: { justificatif_motivation: fake_justificatif } }, format: :turbo_stream }

        it 'attachs a justificatif' do
          subject

          dossier.reload
          expect(dossier.state).to eq(Dossier.states.fetch(:refuse))
          expect(dossier.justificatif_motivation).to be_attached
        end

        it { expect(subject.body).to include('header-top') }
      end

      context 'with dossier in batch_operation' do
        let!(:batch_operation) { create(:batch_operation, operation: :archiver, dossiers: [dossier], instructeur: instructeur) }
        subject { post :terminer, params: { process_action: "refuser", procedure_id: procedure.id, dossier_id: dossier.id }, format: :turbo_stream }

        it { expect { subject }.not_to change { dossier.reload.state } }
        it { is_expected.to redirect_to(instructeur_dossier_path(dossier.procedure, dossier)) }
        it 'flashes message' do
          subject
          expect(flash.alert).to eq("Votre action n'a pas été effectuée, ce dossier fait parti d'un traitement de masse.")
        end
      end
    end

    context "with for_tiers" do
      before do
        dossier_for_tiers.passer_en_instruction!(instructeur: instructeur)
        sign_in(instructeur.user)
      end
      context 'without continuation' do
        subject { post :terminer, params: { process_action: "classer_sans_suite", procedure_id: procedure.id, dossier_id: dossier_for_tiers.id }, format: :turbo_stream }

        it 'Notification email is sent' do
          expect(NotificationMailer).to receive(:send_sans_suite_notification)
            .with(dossier_for_tiers).and_return(NotificationMailer)
          expect(NotificationMailer).to receive(:deliver_later)

          expect(NotificationMailer).to receive(:send_notification_for_tiers)
            .with(dossier_for_tiers).and_return(NotificationMailer)
          expect(NotificationMailer).to receive(:deliver_later)

          subject
        end

        it '2 emails are sent' do
          expect { perform_enqueued_jobs { subject } }.to change { ActionMailer::Base.deliveries.count }.by(2)
        end
      end
    end

    context "with for_tiers_without_notif" do
      before do
        dossier_for_tiers_without_notif.passer_en_instruction!(instructeur: instructeur)
        sign_in(instructeur.user)
      end
      context 'without continuation' do
        subject { post :terminer, params: { process_action: "classer_sans_suite", procedure_id: procedure.id, dossier_id: dossier_for_tiers_without_notif.id }, format: :turbo_stream }

        it 'Notification email is sent' do
          expect(NotificationMailer).to receive(:send_sans_suite_notification)
            .with(dossier_for_tiers_without_notif).and_return(NotificationMailer)
          expect(NotificationMailer).to receive(:deliver_later)

          expect(NotificationMailer).to receive(:send_notification_for_tiers)
            .with(dossier_for_tiers_without_notif).and_return(NotificationMailer)
          expect(NotificationMailer).to receive(:deliver_later)

          subject
        end

        it 'only one email is sent' do
          expect { perform_enqueued_jobs { subject } }.to change { ActionMailer::Base.deliveries.count }.by(1)
        end
      end
    end

    context "with accuse de lecture procedure" do
      before do
        dossier_accuse_lecture.passer_en_instruction!(instructeur: instructeur)
        sign_in(instructeur.user)
      end
      context 'with classer_sans_suite' do
        subject { post :terminer, params: { process_action: "classer_sans_suite", procedure_id: procedure_accuse_lecture.id, dossier_id: dossier_accuse_lecture.id }, format: :turbo_stream }

        it 'Notification accuse de lecture email is sent and not the others' do
          expect(NotificationMailer).to receive(:send_accuse_lecture_notification)
            .with(dossier_accuse_lecture).and_return(NotificationMailer)
          expect(NotificationMailer).to receive(:deliver_later)

          expect(NotificationMailer).not_to receive(:send_sans_suite_notification)
            .with(dossier_accuse_lecture)

          subject
        end

        it { expect(subject.body).to include('header-top') }

        it 'creates a commentaire' do
          expect { subject }.to change { Commentaire.count }.by(1)
          expect(dossier_accuse_lecture.commentaires.last.body).to eq("<p>Bonjour,</p><p>Nous vous informons qu'une décision sur votre dossier a été rendue.</p>Cordialement,<br>#{procedure_accuse_lecture.service.nom}")
        end
      end
    end

    context "with classer_sans_suite" do
      before do
        dossier.passer_en_instruction!(instructeur: instructeur)
        sign_in(instructeur.user)
      end
      context 'without attachment' do
        subject { post :terminer, params: { process_action: "classer_sans_suite", procedure_id: procedure.id, dossier_id: dossier.id }, format: :turbo_stream }

        it 'change state to sans_suite' do
          subject

          dossier.reload
          expect(dossier.state).to eq(Dossier.states.fetch(:sans_suite))
          expect(dossier.justificatif_motivation).to_not be_attached
        end

        it 'Notification email is sent' do
          expect(NotificationMailer).to receive(:send_sans_suite_notification)
            .with(dossier).and_return(NotificationMailer)
          expect(NotificationMailer).to receive(:deliver_later)

          expect(NotificationMailer).not_to receive(:send_notification_for_tiers)
            .with(dossier)

          subject
        end

        it { expect(subject.body).to include('header-top') }
      end

      context 'with attachment' do
        subject { post :terminer, params: { process_action: "classer_sans_suite", procedure_id: procedure.id, dossier_id: dossier.id, dossier: { justificatif_motivation: fake_justificatif } }, format: :turbo_stream }

        it 'change state to sans_suite' do
          subject

          dossier.reload
          expect(dossier.state).to eq(Dossier.states.fetch(:sans_suite))
          expect(dossier.justificatif_motivation).to be_attached
        end

        it { expect(subject.body).to include('header-top') }
      end
    end

    context "with accepter" do
      before do
        dossier.passer_en_instruction!(instructeur: instructeur)
        sign_in(instructeur.user)

        expect(NotificationMailer).to receive(:send_accepte_notification)
          .with(dossier)
          .and_return(NotificationMailer)

        expect(NotificationMailer).to receive(:deliver_later)
      end

      subject { post :terminer, params: { process_action: "accepter", procedure_id: procedure.id, dossier_id: dossier.id }, format: :turbo_stream }

      it 'change state to accepte' do
        subject

        dossier.reload
        expect(dossier.state).to eq(Dossier.states.fetch(:accepte))
        expect(dossier.justificatif_motivation).to_not be_attached
      end

      context 'when the dossier does not have any attestation' do
        it 'Notification email is sent' do
          subject
        end
      end

      context 'when the dossier has an attestation' do
        before do
          attestation = Attestation.new
          allow(attestation).to receive(:pdf).and_return(double(read: 'pdf', size: 2.megabytes, attached?: false))
          allow(attestation).to receive(:pdf_url).and_return('http://some_document_url')

          allow_any_instance_of(Dossier).to receive(:build_attestation).and_return(attestation)
        end

        it 'The instructeur is sent back to the dossier page' do
          expect(subject.body).to include('header-top')
        end

        context 'and the dossier has already an attestation' do
          it 'should not crash' do
            dossier.attestation = Attestation.new
            dossier.save
            expect(subject.body).to include('header-top')
          end
        end
      end

      context 'when the attestation template uses the motivation field' do
        let(:emailable) { false }
        let(:template) { create(:attestation_template) }
        let(:procedure) { create(:procedure, :published, :for_individual, attestation_template: template, instructeurs: [instructeur]) }

        subject do
          post :terminer, params: {
            process_action: "accepter",
            procedure_id: procedure.id,
            dossier_id: dossier.id,
            dossier: { motivation: "Yallah" }
          }, format: :turbo_stream
        end

        before do
          expect_any_instance_of(AttestationTemplate)
            .to receive(:attestation_for)
            .with(have_attributes(motivation: "Yallah"))
        end

        it { subject }
      end

      context 'with an attachment' do
        subject { post :terminer, params: { process_action: "accepter", procedure_id: procedure.id, dossier_id: dossier.id, dossier: { justificatif_motivation: fake_justificatif } }, format: :turbo_stream }

        it 'change state to accepte' do
          subject

          dossier.reload
          expect(dossier.state).to eq(Dossier.states.fetch(:accepte))
          expect(dossier.justificatif_motivation).to be_attached
        end

        it { expect(subject.body).to include('header-top') }
      end
    end

    context 'when related etablissement is still in degraded_mode' do
      let(:procedure) { create(:procedure, :published, for_individual: false, instructeurs: instructeurs) }
      let(:dossier) { create(:dossier, :en_instruction, :with_entreprise, procedure: procedure, as_degraded_mode: true) }

      subject { post :terminer, params: { process_action: "accepter", procedure_id: procedure.id, dossier_id: dossier.id }, format: :turbo_stream }

      context "with accepter" do
        it 'warns about the error' do
          subject
          dossier.reload
          expect(dossier.state).to eq(Dossier.states.fetch(:en_instruction))

          expect(response).to have_http_status(:ok)
          expect(response.body).to match(/Les données relatives au SIRET .+ de le passer accepté/)
        end
      end
    end

    context 'when a dossier is already closed' do
      let(:dossier) { create(:dossier, :accepte, procedure: procedure) }

      before { allow(dossier).to receive(:after_accepter) }

      subject { post :terminer, params: { process_action: "accepter", procedure_id: procedure.id, dossier_id: dossier.id, dossier: { justificatif_motivation: fake_justificatif } }, format: :turbo_stream }

      it 'does not close it again' do
        subject

        expect(dossier).not_to have_received(:after_accepter)
        expect(dossier.state).to eq(Dossier.states.fetch(:accepte))

        expect(response).to have_http_status(:ok)
        expect(response.body).to include('Le dossier est déjà accepté.')
      end
    end
  end

  describe '#pending_correction' do
    let(:message) { 'do that' }
    let(:justificatif) { nil }
    let(:reason) { nil }

    subject do
      post :pending_correction, params: {
        procedure_id: procedure.id, dossier_id: dossier.id,
        dossier: { motivation: message, justificatif_motivation: justificatif },
        reason:
      }, format: :turbo_stream
    end

    before do
      sign_in(instructeur.user)
      expect(controller.current_instructeur).to receive(:mark_tab_as_seen).with(dossier, :messagerie)
    end

    context "dossier en instruction sends an email to user" do
      let(:dossier) { create(:dossier, :en_instruction, :with_individual, procedure:) }

      it { expect { subject }.to have_enqueued_mail(DossierMailer, :notify_pending_correction) }
    end

    context "dossier en instruction" do
      let(:dossier) { create(:dossier, :en_instruction, :with_individual, procedure: procedure) }

      before { subject }

      it 'pass en_construction and create a pending correction' do
        expect(response).to have_http_status(:ok)
        expect(response.body).to include('en attente de correction')

        expect(dossier.reload).to be_en_construction
        expect(dossier).to be_pending_correction
        expect(dossier.corrections.last).to be_dossier_incorrect
      end

      it 'create a comment with text body' do
        expect(dossier.commentaires.last.body).to eq("do that")
        expect(dossier.commentaires.last).to be_flagged_pending_correction
      end

      context 'flagged as incomplete' do
        let(:reason) { 'incomplete' }

        it 'create a correction of incomplete reason' do
          expect(dossier.corrections.last).to be_dossier_incomplete
        end
      end

      context 'with an attachment' do
        let(:justificatif) { fake_justificatif }

        it 'attach file to comment' do
          expect(dossier.commentaires.last.piece_jointe).to be_attached
        end
      end

      context 'with an invalid comment / attachment' do
        let(:justificatif) { Rack::Test::UploadedFile.new(Rails.root.join('Gemfile.lock'), 'text/lock') }

        it 'does not save anything' do
          expect(dossier.reload).not_to be_pending_correction
          expect(dossier.commentaires.count).to eq(0)
          expect(response.body).to include('pas d’un type accepté')
        end
      end

      context 'with an empty message' do
        let(:message) { '' }

        it 'requires a message' do
          expect(dossier.reload).not_to be_pending_correction
          expect(dossier.commentaires.count).to eq(0)
          expect(response.body).to include('Vous devez préciser')
        end
      end

      context 'dossier already having pending corrections' do
        before do
          create(:dossier_correction, dossier:)
        end

        it 'does not create an new pending correction' do
          expect { subject }.not_to change { DossierCorrection.count }
        end

        it 'shows a flash alert' do
          subject

          expect(response.body).to include('')
        end
      end
    end

    context 'dossier en_construction' do
      it 'can create a pending correction' do
        subject
        expect(dossier.reload).to be_pending_correction
        expect(dossier.commentaires.last).to be_flagged_pending_correction
      end
    end

    context 'dossier is termine' do
      let(:dossier) { create(:dossier, :accepte, :with_individual, procedure: procedure) }

      it 'does not create a pending correction' do
        expect { subject }.not_to change { DossierCorrection.count }
        expect(response.body).to include('Impossible')
      end
    end
  end

  describe '#messagerie' do
    before { expect(controller.current_instructeur).to receive(:mark_tab_as_seen).with(dossier, :messagerie) }
    subject { get :messagerie, params: { procedure_id: procedure.id, dossier_id: dossier.id } }
    it { expect(subject).to have_http_status(:ok) }
  end

  describe "#create_commentaire" do
    let(:saved_commentaire) { dossier.commentaires.first }
    let(:body) { "avant\napres" }
    let(:file) { fixture_file_upload('spec/fixtures/files/piece_justificative_0.pdf', 'application/pdf') }
    let(:scan_result) { true }
    let(:now) { Timecop.freeze("09/11/1989") }

    subject {
      post :create_commentaire, params: {
        procedure_id: procedure.id,
        dossier_id: dossier.id,
        commentaire: {
          body: body,
          file: file
        }
      }
    }

    before do
      expect(controller.current_instructeur).to receive(:mark_tab_as_seen).with(dossier, :messagerie)
      allow(ClamavService).to receive(:safe_file?).and_return(scan_result)
      Timecop.freeze(now)
    end

    after { Timecop.return }

    it "creates a commentaire" do
      expect { subject }.to change(Commentaire, :count).by(1)
      expect(instructeur.followed_dossiers).to include(dossier)

      expect(response).to redirect_to(messagerie_instructeur_dossier_path(dossier.procedure, dossier))
      expect(flash.notice).to be_present
      expect(dossier.reload.last_commentaire_updated_at).to eq(now)
    end

    context "when the commentaire created with virus file" do
      let(:scan_result) { false }

      it "creates a commentaire (shows message that file have a virus)" do
        expect { subject }.to change(Commentaire, :count).by(1)
        expect(instructeur.followed_dossiers).to include(dossier)

        expect(response).to redirect_to(messagerie_instructeur_dossier_path(dossier.procedure, dossier))
        expect(flash.notice).to be_present
      end
    end

    context "when the dossier is deleted by user" do
      let(:dossier) { create(:dossier, :accepte, procedure: procedure) }

      before do
        dossier.update!(hidden_by_user_at: 1.hour.ago)
        subject
      end

      it "does not create a commentaire" do
        expect { subject }.to change(Commentaire, :count).by(0)
        expect(flash.alert).to be_present
      end
    end
  end

  describe "#create_avis" do
    let(:expert) { create(:expert) }
    let(:experts_procedure) { create(:experts_procedure, expert: expert, procedure: dossier.procedure) }
    let(:invite_linked_dossiers) { false }
    let(:saved_avis) { dossier.avis.first }
    let!(:old_avis_count) { Avis.count }

    before do
      expect(controller.current_instructeur).to receive(:mark_tab_as_seen).with(dossier, :avis)
    end

    subject do
      post :create_avis, params: {
        procedure_id: procedure.id,
        dossier_id: dossier.id,
        avis: { emails: emails, introduction: 'intro', confidentiel: true, invite_linked_dossiers: invite_linked_dossiers, claimant: instructeur, experts_procedure: experts_procedure }
      }
    end

    let(:emails) { "[\"email@a.com\"]" }

    context "notifications updates" do
      context 'when an instructeur follows the dossier' do
        let(:follower) { create(:instructeur) }
        before { follower.follow(dossier) }

        it 'the follower has a notification' do
          expect(follower.followed_dossiers.with_notifications).to eq([])
          subject
          expect(follower.followed_dossiers.with_notifications).to eq([dossier.reload])
        end
      end
    end

    context 'as an instructeur, i auto follow the dossier so I get the notifications' do
      it 'works' do
        subject
        expect(instructeur.followed_dossiers).to match_array([dossier])
      end
    end

    context 'email sending' do
      before do
        subject
      end

      it { expect(saved_avis.expert.email).to eq('email@a.com') }
      it { expect(saved_avis.introduction).to eq('intro') }
      it { expect(saved_avis.confidentiel).to eq(true) }
      it { expect(saved_avis.dossier).to eq(dossier) }
      it { expect(saved_avis.claimant).to eq(instructeur) }
      it { expect(response).to redirect_to(avis_instructeur_dossier_path(dossier.procedure, dossier)) }

      context "with an invalid email" do
        let(:emails) { "[\"emaila.com\"]" }

        before { subject }

        it { expect(response).to render_template :avis }
        it { expect(flash.alert).to eq(["emaila.com : Le champ « Email » est invalide. Saisir une adresse électronique valide, exemple : john.doe@exemple.fr"]) }
        it { expect { subject }.not_to change(Avis, :count) }
        it { expect(dossier.last_avis_updated_at).to eq(nil) }
      end

      context "with no email" do
        let(:emails) { "" }

        before { subject }

        it { expect(response).to render_template :avis }
        it { expect(flash.alert).to eq("Le champ « Emails » doit être rempli") }
        it { expect { subject }.not_to change(Avis, :count) }
        it { expect(dossier.last_avis_updated_at).to eq(nil) }
      end

      context 'with multiple emails' do
        let(:emails) { "[\"toto.fr\",\"titi@titimail.com\"]" }

        before { subject }

        it { expect(response).to render_template :avis }
        it { expect(flash.alert).to eq(["toto.fr : Le champ « Email » est invalide. Saisir une adresse électronique valide, exemple : john.doe@exemple.fr"]) }
        it { expect(flash.notice).to eq("Une demande d’avis a été envoyée à titi@titimail.com") }
        it { expect(Avis.count).to eq(old_avis_count + 1) }
        it { expect(saved_avis.expert.email).to eq("titi@titimail.com") }
      end

      context 'when the expert do not want to receive notification' do
        let(:emails) { "[\"email@a.com\"]" }
        let(:experts_procedure) { create(:experts_procedure, expert: expert, procedure: dossier.procedure, notify_on_new_avis: false) }

        before { subject }
      end

      context 'with linked dossiers' do
        let(:asked_confidentiel) { false }
        let(:previous_avis_confidentiel) { false }
        let(:dossier) { create(:dossier, :en_construction, :with_dossier_link, procedure: procedure) }
        before { subject }
        context 'when the expert doesn’t share linked dossiers' do
          let(:invite_linked_dossiers) { false }

          it 'sends a single avis for the main dossier, but doesn’t give access to the linked dossiers' do
            expect(flash.notice).to eq("Une demande d’avis a été envoyée à email@a.com")
            expect(Avis.count).to eq(old_avis_count + 1)
            expect(saved_avis.expert.email).to eq("email@a.com")
            expect(saved_avis.dossier).to eq(dossier)
          end
        end

        context 'when the expert also shares the linked dossiers' do
          let(:invite_linked_dossiers) { true }

          context 'and the expert can access the linked dossiers' do
            let(:saved_avis) { Avis.last(2).first }
            let(:linked_avis) { Avis.last }
            let(:linked_dossier) { Dossier.find_by(id: dossier.reload.champs_public.filter(&:dossier_link?).filter_map(&:value)) }
            let(:invite_linked_dossiers) do
              instructeur.assign_to_procedure(linked_dossier.procedure)
              true
            end

            it 'sends one avis for the main dossier' do
              expect(flash.notice).to eq("Une demande d’avis a été envoyée à email@a.com")
              expect(saved_avis.expert.email).to eq("email@a.com")
              expect(saved_avis.dossier).to eq(dossier)
            end

            it 'sends another avis for the linked dossiers' do
              expect(Avis.count).to eq(old_avis_count + 2)
              expect(linked_avis.dossier).to eq(linked_dossier)
            end
          end

          context 'but the expert can’t access the linked dossier' do
            it 'sends a single avis for the main dossier, but doesn’t give access to the linked dossiers' do
              expect(flash.notice).to eq("Une demande d’avis a été envoyée à email@a.com")
              expect(Avis.count).to eq(old_avis_count + 1)
              expect(saved_avis.expert.email).to eq("email@a.com")
              expect(saved_avis.dossier).to eq(dossier)
            end
          end
        end
      end
    end
  end

  describe "#show" do
    context "when the dossier is exported as PDF" do
      let(:instructeur) { create(:instructeur) }
      let(:expert) { create(:expert) }
      let(:procedure) { create(:procedure, :published, instructeurs: instructeurs) }
      let(:experts_procedure) { create(:experts_procedure, expert: expert, procedure: procedure) }
      let(:dossier) do
        create(:dossier,
          :accepte,
          :with_populated_champs,
          :with_populated_annotations,
          :with_motivation,
          :with_entreprise,
          :with_commentaires, procedure: procedure)
      end
      let!(:avis) { create(:avis, dossier: dossier, claimant: instructeur, experts_procedure: experts_procedure) }

      subject do
        avis
        get :show, params: {
          procedure_id: procedure.id,
          dossier_id: dossier.id,
          format: :pdf
        }
      end

      before do
        expect(controller.current_instructeur).to receive(:mark_tab_as_seen).with(dossier, :demande)
        subject
      end

      it { expect(assigns(:acls)).to eq(PiecesJustificativesService.new(user_profile: instructeur).acl_for_dossier_export(dossier.procedure)) }
      it { expect(assigns(:is_dossier_in_batch_operation)).to eq(false) }
      it { expect(response).to render_template 'dossiers/show' }

      context 'empty champs commune' do
        let(:procedure) { create(:procedure, :published, types_de_champ_public: [{ type: :communes }], instructeurs:) }
        let(:dossier) { create(:dossier, :accepte, procedure:) }

        it { expect(response).to render_template 'dossiers/show' }
      end
    end

    context 'with dossier in batch_operation' do
      let!(:batch_operation) { create(:batch_operation, operation: :archiver, dossiers: [dossier], instructeur: instructeur) }
      it 'assigns variable with true value' do
        get :show, params: { procedure_id: procedure.id, dossier_id: dossier.id }
        expect(assigns(:is_dossier_in_batch_operation)).to eq(true)
      end
    end
  end

  describe "#update_annotations" do
    let(:procedure) do
      create(:procedure, :published, types_de_champ_public:, types_de_champ_private:, instructeurs: instructeurs)
    end
    let(:types_de_champ_private) do
      [
        { type: :multiple_drop_down_list },
        { type: :linked_drop_down_list },
        { type: :datetime },
        { type: :repetition, children: [{}] },
        { type: :drop_down_list, options: [:a, :b, :other] }
      ]
    end
    let(:types_de_champ_public) { [] }
    let(:dossier) { create(:dossier, :en_construction, :with_populated_annotations, procedure: procedure) }
    let(:another_instructeur) { create(:instructeur) }
    let(:now) { Time.zone.parse('01/01/2100') }

    let(:champ_multiple_drop_down_list) { dossier.champs_private.first }
    let(:champ_linked_drop_down_list) { dossier.champs_private.second }
    let(:champ_datetime) { dossier.champs_private.third }
    let(:champ_repetition) { dossier.champs_private.fourth }
    let(:champ_drop_down_list) { dossier.champs_private.fifth }

    context 'when no invalid champs_public' do
      context "with new values for champs_private" do
        before do
          expect(controller.current_instructeur).to receive(:mark_tab_as_seen).with(dossier, :annotations_privees)
          another_instructeur.follow(dossier)
          Timecop.freeze(now)
          patch :update_annotations, params: params, format: :turbo_stream

          champ_multiple_drop_down_list.reload
          champ_linked_drop_down_list.reload
          champ_datetime.reload
          champ_repetition.reload
          champ_drop_down_list.reload
        end

        after do
          Timecop.return
        end
        let(:params) do
          {
            procedure_id: procedure.id,
            dossier_id: dossier.id,
            dossier: {
              champs_private_attributes: {
                champ_multiple_drop_down_list.public_id => {
                  with_public_id: true,
                  value: ['', 'val1', 'val2']
                },
                champ_datetime.public_id => {
                  with_public_id: true,
                  value: '2019-12-21T13:17'
                },
                champ_linked_drop_down_list.public_id => {
                  with_public_id: true,
                  primary_value: 'primary',
                  secondary_value: 'secondary'
                },
                champ_repetition.champs.first.public_id => {
                  with_public_id: true,
                  value: 'text'
                },
                champ_drop_down_list.public_id => {
                  with_public_id: true,
                  value: '__other__',
                  value_other: 'other value'
                }
              }
            }
          }
        end

        it {
          expect(champ_multiple_drop_down_list.value).to eq('["val1","val2"]')
          expect(champ_linked_drop_down_list.primary_value).to eq('primary')
          expect(champ_linked_drop_down_list.secondary_value).to eq('secondary')
          expect(champ_datetime.value).to eq(Time.zone.parse('2019-12-21T13:17:00').iso8601)
          expect(champ_repetition.champs.first.value).to eq('text')
          expect(champ_drop_down_list.value).to eq('other value')
          expect(dossier.reload.last_champ_private_updated_at).to eq(now)
          expect(response).to have_http_status(200)

          expect(ChampRevision.where(champ_id: champ_datetime.id).first.instructeur_id).to eq(instructeur.id)
          expect(ChampRevision.where(champ_id: champ_datetime.id).first.updated_at).to eq(now)
          expect(ChampRevision.where(champ_id: champ_linked_drop_down_list.id).first.instructeur_id).to eq(instructeur.id)
          expect(ChampRevision.where(champ_id: champ_linked_drop_down_list.id).first.updated_at).to eq(now)
          expect(ChampRevision.where(champ_id: champ_drop_down_list.id).first.instructeur_id).to eq(instructeur.id)
          expect(ChampRevision.where(champ_id: champ_drop_down_list.id).first.updated_at).to eq(now)

          assert_enqueued_jobs(1, only: DossierIndexSearchTermsJob)
        }

        it 'updates the annotations' do
          Timecop.travel(now + 1.hour)
          expect(instructeur.followed_dossiers.with_notifications).to eq([])
          expect(another_instructeur.followed_dossiers.with_notifications).to eq([dossier.reload])
        end
      end

      context "without new values for champs_private" do
        let(:params) do
          {
            procedure_id: procedure.id,
            dossier_id: dossier.id,
            dossier: {
              champs_private_attributes: {},
              champs_public_attributes: {
                '0': {
                  id: champ_multiple_drop_down_list.id,
                  value: ['', 'val1', 'val2']
                }
              }
            }
          }
        end

        it {
          expect(dossier.reload.last_champ_private_updated_at).to eq(nil)
          expect(response).to have_http_status(200)
        }
      end
    end

    after do
      Timecop.return
    end

    context "with new values for champs_private (legacy)" do
      let(:params) do
        {
          procedure_id: procedure.id,
          dossier_id: dossier.id,
          dossier: {
            champs_private_attributes: {
              '0': {
                id: champ_datetime.id,
                value: '2024-03-30T07:03'
              }
            }
          }
        }
      end

      it 'update champs_private' do
        patch :update_annotations, params: params, format: :turbo_stream
        champ_datetime.reload
        expect(champ_datetime.value).to eq(Time.zone.parse('2024-03-30T07:03:00').iso8601)
      end
    end

    context "without new values for champs_private" do
      let(:params) do
        {
          procedure_id: procedure.id,
          dossier_id: dossier.id,
          dossier: {
            champs_private_attributes: {},
            champs_public_attributes: {
              champ_multiple_drop_down_list.public_id => {
                with_public_id: true,
                value: ['', 'val1', 'val2']
              }
            }
          }
        }
      end

      it {
        expect(dossier.reload.last_champ_private_updated_at).to eq(nil)
        expect(response).to have_http_status(200)
      }
    end

    context "with invalid champs_public (DecimalNumberChamp)" do
      let(:types_de_champ_public) do
        [
          { type: :decimal_number }
        ]
      end

      let(:champ_decimal_number) { dossier.champs_public.first }

      let(:params) do
        {
          procedure_id: procedure.id,
          dossier_id: dossier.id,
          dossier: {
            champs_private_attributes: {
              champ_datetime.public_id => {
                with_public_id: true,
                value: '2024-03-30T07:03'
              }
            }
          }
        }
      end

      it 'update champs_private' do
        too_long_float = '3.1415'
        champ_decimal_number.update_column(:value, too_long_float)
        patch :update_annotations, params: params, format: :turbo_stream
        champ_datetime.reload
        expect(champ_datetime.value).to eq(Time.zone.parse('2024-03-30T07:03:00').iso8601)
      end
    end
  end

  describe "#telecharger_pjs" do
    subject do
      get :telecharger_pjs, params: {
        procedure_id: procedure.id,
        dossier_id: dossier.id
      }
    end

    before do
      allow_any_instance_of(PiecesJustificativesService).to receive(:generate_dossiers_export).with([dossier]).and_call_original
    end

    it 'includes an attachment' do
      expect(subject.headers['Content-Disposition']).to start_with('attachment; ')
    end

    it 'the attachment.zip is extractable' do
      content = ZipTricks::FileReader.read_zip_structure(io: StringIO.new(subject.body))
      file_names = content.map(&:filename)
      expect(file_names.size).to eq(1)
      expect(file_names.first).to start_with("dossier-#{dossier.id}/export-")
    end
  end

  describe "#destroy" do
    let(:batch_operation) {}
    subject do
      batch_operation
      delete :destroy, params: {
        procedure_id: procedure.id,
        dossier_id: dossier.id
      }
    end

    before do
      dossier.passer_en_instruction(instructeur: instructeur)
    end

    context 'just before delete the dossier, the operation must be equal to 2' do
      before do
        dossier.accepter!(instructeur: instructeur, motivation: 'le dossier est correct')
      end

      it 'has 2 operations logs before deletion' do
        expect(DossierOperationLog.where(dossier_id: dossier.id).count).to eq(2)
      end
    end

    context 'when the instructeur want to delete a dossier with a decision and already hidden by user' do
      before do
        dossier.accepter!(instructeur: instructeur, motivation: "le dossier est correct")
        dossier.update!(hidden_by_user_at: Time.zone.now.beginning_of_day.utc)
        subject
      end

      it 'deletes previous logs and add a suppression log' do
        expect(DossierOperationLog.where(dossier_id: dossier.id).count).to eq(3)
        expect(DossierOperationLog.where(dossier_id: dossier.id).last.operation).to eq('supprimer')
      end

      it 'does not add a record into deleted_dossiers table' do
        expect(DeletedDossier.where(dossier_id: dossier.id).count).to eq(0)
      end

      it 'is not visible by administration' do
        expect(dossier.reload.visible_by_administration?).to be_falsy
      end
    end

    context 'when the instructeur want to delete a dossier with a decision and not hidden by user' do
      before do
        dossier.accepter!(instructeur: instructeur, motivation: "le dossier est correct")
        subject
      end

      it 'does not deletes previous logs and adds a suppression log' do
        expect(DossierOperationLog.where(dossier_id: dossier.id).count).to eq(3)
        expect(DossierOperationLog.where(dossier_id: dossier.id).last.operation).to eq('supprimer')
      end

      it 'add a record into deleted_dossiers table' do
        expect(DeletedDossier.where(dossier_id: dossier.id).count).to eq(0)
      end

      it 'does not discard the dossier' do
        expect(dossier.reload.hidden_at).to eq(nil)
      end

      it 'fill hidden by reason' do
        expect(dossier.reload.hidden_by_reason).not_to eq(nil)
        expect(dossier.reload.hidden_by_reason).to eq("instructeur_request")
      end
    end

    context 'when the instructeur want to delete a dossier without a decision' do
      before do
        subject
      end

      it 'does not delete the dossier' do
        expect { dossier.reload }.not_to raise_error # A deleted dossier would raise an ActiveRecord::RecordNotFound
      end

      it 'does not add a record into deleted_dossiers table' do
        expect(DeletedDossier.where(dossier_id: dossier.id).count).to eq(0)
      end
    end

    context 'with dossier in batch_operation' do
      let(:batch_operation) { create(:batch_operation, operation: :archiver, dossiers: [dossier], instructeur: instructeur) }
      it { expect { subject }.not_to change { dossier.reload.hidden_at } }
      it { is_expected.to redirect_to(instructeur_dossier_path(dossier.procedure, dossier)) }
      it 'flashes message' do
       subject
       expect(flash.alert).to eq("Votre action n'a pas été effectuée, ce dossier fait parti d'un traitement de masse.")
     end
    end
  end

  describe '#extend_conservation' do
    subject { post :extend_conservation, params: { procedure_id: procedure.id, dossier_id: dossier.id } }
    context 'when user logged in' do
      it 'works' do
        expect(subject).to redirect_to(instructeur_dossier_path(procedure, dossier))
      end

      it 'extends conservation_extension by 1 month' do
        subject
        expect(dossier.reload.conservation_extension).to eq(1.month)
      end

      it 'flashed notice success' do
        subject
        expect(flash[:notice]).to eq(I18n.t('views.instructeurs.dossiers.archived_dossier'))
      end
    end

    context 'with dossier in batch_operation' do
       let!(:batch_operation) { create(:batch_operation, operation: :archiver, dossiers: [dossier], instructeur: instructeur) }
       it { expect { subject }.not_to change { dossier.reload.conservation_extension } }
       it { is_expected.to redirect_to(instructeur_dossier_path(dossier.procedure, dossier)) }
       it 'flashes message' do
         subject
         expect(flash.alert).to eq("Votre action n'a pas été effectuée, ce dossier fait parti d'un traitement de masse.")
       end
     end
  end

  describe '#restore' do
    let(:instructeur) { create(:instructeur) }
    let!(:gi_p1_1) { GroupeInstructeur.create(label: '1', procedure: procedure) }
    let!(:procedure) { create(:procedure, :published, :for_individual, instructeurs: [instructeur]) }
    let!(:dossier) { create(:dossier, :accepte, :with_individual, procedure: procedure, groupe_instructeur: procedure.groupe_instructeurs.first, hidden_by_administration_at: 1.hour.ago) }
    let(:batch_operation) {}
    before do
      sign_in(instructeur.user)
      batch_operation
      instructeur.groupe_instructeurs << gi_p1_1
      patch :restore,
      params: {
        procedure_id: procedure.id,
        dossier_id: dossier.id
      }
    end

    it "puts hidden_by_administration_at to nil" do
      expect(dossier.reload.hidden_by_administration_at).to eq(nil)
    end

    context 'with dossier in batch_operation' do
      let(:batch_operation) { create(:batch_operation, operation: :archiver, dossiers: [dossier], instructeur: instructeur) }
      it { expect(dossier.hidden_by_administration_at).not_to eq(nil) }
      it { expect(response).to redirect_to(instructeur_dossier_path(dossier.procedure, dossier)) }
      it { expect(flash.alert).to eq("Votre action n'a pas été effectuée, ce dossier fait parti d'un traitement de masse.") }
    end
  end

  describe '#reaffectation' do
    let!(:gi_2) { GroupeInstructeur.create(label: 'deuxième groupe', procedure: procedure) }
    let!(:gi_3) { GroupeInstructeur.create(label: 'troisième groupe', procedure: procedure) }
    let!(:dossier) { create(:dossier, :en_construction, procedure: procedure, groupe_instructeur: procedure.groupe_instructeurs.first) }

    before do
      post :reaffectation,
         params: {
           procedure_id: procedure.id,
           dossier_id: dossier.id
         }
    end

    it do
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Vous pouvez réaffecter le dossier nº #{dossier.id} à l’un des groupes d’instructeurs suivants.")
      expect(response.body).to include('2 groupes existent')
    end
  end

  describe '#reaffecter' do
    let!(:gi_1) { procedure.groupe_instructeurs.first }
    let!(:gi_2) { GroupeInstructeur.create(label: 'deuxième groupe', procedure: procedure) }
    let!(:dossier) { create(:dossier, :en_construction, :with_individual, procedure: procedure, groupe_instructeur: gi_1) }
    let!(:new_instructeur) { create(:instructeur) }

    before do
      gi_1.instructeurs << new_instructeur
      new_instructeur.followed_dossiers << dossier

      post :reaffecter,
        params: {
          procedure_id: procedure.id,
          dossier_id: dossier.id,
          groupe_instructeur_id: gi_2.id
        }
    end

    it do
      expect(dossier.reload.groupe_instructeur.id).to eq(gi_2.id)
      expect(dossier.forced_groupe_instructeur).to be_truthy
      expect(dossier.followers_instructeurs).to eq []
      expect(dossier.dossier_assignment.previous_groupe_instructeur_id).to eq(gi_1.id)
      expect(dossier.dossier_assignment.previous_groupe_instructeur_label).to eq(gi_1.label)
      expect(dossier.dossier_assignment.groupe_instructeur_id).to eq(gi_2.id)
      expect(dossier.dossier_assignment.groupe_instructeur_label).to eq(gi_2.label)
      expect(dossier.dossier_assignment.mode).to eq('manual')
      expect(dossier.dossier_assignment.assigned_by).to eq(instructeur.email)
      expect(response).to redirect_to(instructeur_procedure_path(procedure))
      expect(flash.notice).to eq("Le dossier nº #{dossier.id} a été réaffecté au groupe d’instructeurs « deuxième groupe ».")
    end
  end

  describe '#personnes_impliquees' do
    let(:routed_procedure) { create(:procedure, :routee, :published, :for_individual) }
    let(:gi_1) { routed_procedure.groupe_instructeurs.first }
    let(:gi_2) { routed_procedure.groupe_instructeurs.last }
    let(:dossier) { create(:dossier, :en_construction, :with_individual, procedure: routed_procedure, groupe_instructeur: gi_1) }
    let(:new_instructeur) { create(:instructeur) }

    before do
      gi_1.instructeurs << new_instructeur
      gi_2.instructeurs << instructeur
      new_instructeur.followed_dossiers << dossier
      dossier.assign_to_groupe_instructeur(gi_2, DossierAssignment.modes.fetch(:manual), new_instructeur)

      get :personnes_impliquees,
        params: {
          procedure_id: routed_procedure.id,
          dossier_id: dossier.id
        }
    end

    it do
      expect(response.body).to include('a réaffecté ce dossier du groupe « défaut » au groupe « deuxième groupe »')
    end
  end

  describe '#print' do
    let(:dossier) { create(:dossier, :en_construction, procedure: procedure) }

    subject do
      get :print, params: {
        procedure_id: procedure.id,
        dossier_id: dossier.id
      }
    end

    it { expect(subject).to have_http_status(:ok) }
  end

  describe '#pieces_jointes' do
    let(:procedure) { create(:procedure, :published, types_de_champ_public: [{ type: :piece_justificative }], instructeurs:) }
    let(:dossier) { create(:dossier, :en_construction, :with_populated_champs, procedure: procedure) }
    let(:path) { 'spec/fixtures/files/logo_test_procedure.png' }

    before do
      dossier.champs.first.piece_justificative_file.attach(
        io: File.open(path),
        filename: "logo_test_procedure.png",
        content_type: "image/png",
        metadata: { virus_scan_result: ActiveStorage::VirusScanner::SAFE }
      )
      get :pieces_jointes, params: {
        procedure_id: procedure.id,
        dossier_id: dossier.id
      }
    end

    it do
      expect(response.body).to include('Télécharger le fichier toto.txt')
      expect(response.body).to include('Télécharger le fichier logo_test_procedure.png')
      expect(response.body).to include('Visualiser')
    end
  end
end
