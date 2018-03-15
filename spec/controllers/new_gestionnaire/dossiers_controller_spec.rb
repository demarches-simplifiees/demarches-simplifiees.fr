require 'spec_helper'

describe NewGestionnaire::DossiersController, type: :controller do
  render_views

  let(:gestionnaire) { create(:gestionnaire) }
  let(:gestionnaires) { [gestionnaire] }
  let(:procedure) { create(:procedure, :published, gestionnaires: gestionnaires) }
  let(:dossier) { create(:dossier, :en_construction, procedure: procedure) }

  before { sign_in(gestionnaire) }

  describe '#attestation' do
    context 'when a dossier has an attestation' do
      let(:fake_pdf) { double(read: 'pdf content') }
      let!(:dossier) { create(:dossier, :en_construction, attestation: Attestation.new, procedure: procedure) }
      let!(:procedure) { create(:procedure, :published, gestionnaires: [gestionnaire]) }
      let!(:dossier) { create(:dossier, :en_construction, attestation: Attestation.new, procedure: procedure) }

      it 'returns the attestation pdf' do
        allow_any_instance_of(Attestation).to receive(:pdf).and_return(fake_pdf)

        expect(controller).to receive(:send_data)
          .with('pdf content', filename: 'attestation.pdf', type: 'application/pdf') do
            controller.head :ok
          end

        get :attestation, params: { procedure_id: procedure.id, dossier_id: dossier.id }
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe '#envoyer_a_accompagnateur' do
    let(:recipient) { create(:gestionnaire) }
    let(:gestionnaires) { [gestionnaire, recipient] }
    let(:mail) { double("mail") }

    before do
      expect(mail).to receive(:deliver_later)

      expect(GestionnaireMailer)
        .to receive(:send_dossier)
        .with(gestionnaire, dossier, recipient)
        .and_return(mail)

      post(
        :envoyer_a_accompagnateur,
        params: {
          recipient: recipient,
          procedure_id: procedure.id,
          dossier_id: dossier.id
        }
      )
    end

    it { expect(response).to redirect_to(personnes_impliquees_gestionnaire_dossier_url) }
  end

  describe '#follow' do
    before do
      patch :follow, params: { procedure_id: procedure.id, dossier_id: dossier.id }
    end

    it { expect(gestionnaire.followed_dossiers).to match([dossier]) }
    it { expect(flash.notice).to eq('Dossier suivi') }
    it { expect(response).to redirect_to(gestionnaire_procedures_url) }
  end

  describe '#unfollow' do
    before do
      gestionnaire.followed_dossiers << dossier
      patch :unfollow, params: { procedure_id: procedure.id, dossier_id: dossier.id }
      gestionnaire.reload
    end

    it { expect(gestionnaire.followed_dossiers).to match([]) }
    it { expect(flash.notice).to eq("Vous ne suivez plus le dossier nº #{dossier.id}") }
    it { expect(response).to redirect_to(gestionnaire_procedures_url) }
  end

  describe '#archive' do
    before do
      gestionnaire.follow(dossier)
      patch :archive, params: { procedure_id: procedure.id, dossier_id: dossier.id }
      dossier.reload
      gestionnaire.reload
    end

    it { expect(dossier.archived).to be true }
    it { expect(response).to redirect_to(gestionnaire_procedures_url) }
    it { expect(gestionnaire.followed_dossiers).not_to include(dossier) }
  end

  describe '#unarchive' do
    before do
      dossier.update(archived: true)
      patch :unarchive, params: { procedure_id: procedure.id, dossier_id: dossier.id }
      dossier.reload
    end

    it { expect(dossier.archived).to be false }
    it { expect(response).to redirect_to(gestionnaire_procedures_url) }
  end

  describe '#passer_en_instruction' do
    before do
      dossier.en_construction!
      sign_in gestionnaire
      post :passer_en_instruction, params: { procedure_id: procedure.id, dossier_id: dossier.id }
      dossier.reload
    end

    it { expect(dossier.state).to eq('en_instruction') }
    it { is_expected.to redirect_to gestionnaire_dossier_path(procedure, dossier) }
    it { expect(gestionnaire.follow?(dossier)).to be true }
  end

  describe '#repasser_en_construction' do
    before do
      dossier.en_instruction!
      sign_in gestionnaire
    end

    subject { post :repasser_en_construction, params: { procedure_id: procedure.id, dossier_id: dossier.id } }

    it 'change state to en_construction' do
      subject

      dossier.reload
      expect(dossier.state).to eq('en_construction')
    end

    it { is_expected.to redirect_to gestionnaire_dossier_path(procedure, dossier) }
  end

  describe '#terminer' do
    context "with refuser" do
      before do
        dossier.en_instruction!
        sign_in gestionnaire
      end

      subject { post :terminer, params: { process_action: "refuser", procedure_id: procedure.id, dossier_id: dossier.id } }

      it 'change state to refuse' do
        subject

        dossier.reload
        expect(dossier.state).to eq('refuse')
      end

      it 'Notification email is sent' do
        expect(NotificationMailer).to receive(:send_notification)
          .with(dossier, kind_of(Mails::RefusedMail), nil).and_return(NotificationMailer)
        expect(NotificationMailer).to receive(:deliver_now!)

        subject
      end

      it { is_expected.to redirect_to redirect_to gestionnaire_dossier_path(procedure, dossier) }
    end

    context "with classer_sans_suite" do
      before do
        dossier.en_instruction!
        sign_in gestionnaire
      end

      subject { post :terminer, params: { process_action: "classer_sans_suite", procedure_id: procedure.id, dossier_id: dossier.id } }

      it 'change state to sans_suite' do
        subject

        dossier.reload
        expect(dossier.state).to eq('sans_suite')
      end

      it 'Notification email is sent' do
        expect(NotificationMailer).to receive(:send_notification)
          .with(dossier, kind_of(Mails::WithoutContinuationMail), nil).and_return(NotificationMailer)
        expect(NotificationMailer).to receive(:deliver_now!)

        subject
      end

      it { is_expected.to redirect_to redirect_to gestionnaire_dossier_path(procedure, dossier) }
    end

    context "with accepter" do
      let(:expected_attestation) { nil }

      before do
        dossier.en_instruction!
        sign_in gestionnaire

        expect(NotificationMailer).to receive(:send_notification)
          .with(dossier, kind_of(Mails::ClosedMail), expected_attestation)
          .and_return(NotificationMailer)

        expect(NotificationMailer).to receive(:deliver_now!)
      end

      subject { post :terminer, params: { process_action: "accepter", procedure_id: procedure.id, dossier_id: dossier.id } }

      it 'change state to accepte' do
        subject

        dossier.reload
        expect(dossier.state).to eq('accepte')
      end

      context 'when the dossier does not have any attestation' do
        it 'Notification email is sent' do
          subject
        end
      end

      context 'when the dossier has an attestation' do
        before do
          attestation = Attestation.new
          allow(attestation).to receive(:pdf).and_return(double(read: 'pdf', size: 2.megabytes))
          allow(attestation).to receive(:emailable?).and_return(emailable)

          expect_any_instance_of(Dossier).to receive(:reload)
          allow_any_instance_of(Dossier).to receive(:build_attestation).and_return(attestation)
        end

        context 'emailable' do
          let(:emailable) { true }
          let(:expected_attestation) { 'pdf' }

          it 'Notification email is sent with the attestation' do
            subject

            is_expected.to redirect_to redirect_to gestionnaire_dossier_path(procedure, dossier)
          end
        end

        context 'when the dossier has an attestation not emailable' do
          let(:emailable) { false }
          let(:expected_attestation) { nil }

          it 'Notification email is sent without the attestation' do
            expect(controller).to receive(:capture_message)

            subject

            is_expected.to redirect_to redirect_to gestionnaire_dossier_path(procedure, dossier)
          end
        end
      end

      context 'when the attestation template uses the motivation field' do
        let(:emailable) { false }
        let(:template) { create(:attestation_template) }
        let(:procedure) { create(:procedure, :published, attestation_template: template, gestionnaires: [gestionnaire]) }

        subject do
          post :terminer, params: {
            process_action: "accepter",
            procedure_id: procedure.id,
            dossier_id: dossier.id,
            dossier: { motivation: "Yallah" }
          }
        end

        before do
          Timecop.freeze(DateTime.now)

          expect_any_instance_of(AttestationTemplate)
            .to receive(:attestation_for)
            .with(have_attributes(motivation: "Yallah", processed_at: DateTime.now))
        end

        after { Timecop.return }

        it { subject }
      end
    end
  end

  describe "#create_commentaire" do
    let(:saved_commentaire) { dossier.commentaires.first }
    let(:body) { "avant\napres" }
    let(:file) { nil }
    let(:scan_result) { true }

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
      allow(ClamavService).to receive(:safe_file?).and_return(scan_result)
    end

    it do
      subject

      expect(saved_commentaire.body).to eq("<p>avant\n<br />apres</p>")
      expect(saved_commentaire.email).to eq(gestionnaire.email)
      expect(saved_commentaire.dossier).to eq(dossier)
      expect(response).to redirect_to(messagerie_gestionnaire_dossier_path(dossier.procedure, dossier))
      expect(gestionnaire.followed_dossiers).to include(dossier)
      expect(saved_commentaire.file.present?).to eq(false)
    end

    it { expect { subject }.to change(Commentaire, :count).by(1) }

    context "without a body" do
      let(:body) { nil }

      it { expect { subject }.not_to change(Commentaire, :count) }
    end

    context "with a file" do
      let(:file) { Rack::Test::UploadedFile.new("./spec/support/files/piece_justificative_0.pdf", 'application/pdf') }

      it { subject; expect(saved_commentaire.file.present?).to eq(true) }
      it { expect { subject }.to change(Commentaire, :count).by(1) }

      context "and a virus" do
        let(:scan_result) { false }

        it { expect { subject }.not_to change(Commentaire, :count) }
      end
    end
  end

  describe "#create_avis" do
    let(:saved_avis) { dossier.avis.first }

    subject do
      post :create_avis, params: {
        procedure_id: procedure.id,
        dossier_id: dossier.id,
        avis: { email: email, introduction: 'intro', confidentiel: true }
      }
    end

    before do
      subject
    end

    let(:email) { 'email@a.com' }

    it { expect(saved_avis.email).to eq('email@a.com') }
    it { expect(saved_avis.introduction).to eq('intro') }
    it { expect(saved_avis.confidentiel).to eq(true) }
    it { expect(saved_avis.dossier).to eq(dossier) }
    it { expect(saved_avis.claimant).to eq(gestionnaire) }
    it { expect(response).to redirect_to(avis_gestionnaire_dossier_path(dossier.procedure, dossier)) }

    context "with an invalid email" do
      let(:email) { 'emaila.com' }

      it { expect(response).to render_template :avis }
      it { expect(flash.alert).to eq(["Email n'est pas valide"]) }
      it { expect { subject }.not_to change(Avis, :count) }
    end
  end

  describe "#update_annotations" do
    let(:champ_multiple_drop_down_list) do
      create(:type_de_champ, :private, type_champ: 'multiple_drop_down_list', libelle: 'libelle').champ.create
    end

    let(:champ_datetime) do
      create(:type_de_champ, :private, type_champ: 'datetime', libelle: 'libelle').champ.create
    end

    let(:dossier) do
      create(:dossier, :en_construction, procedure: procedure, champs_private: [champ_multiple_drop_down_list, champ_datetime])
    end

    before do
      patch :update_annotations, params: {
        procedure_id: procedure.id,
        dossier_id: dossier.id,
        dossier: {
          champs_private_attributes: {
            '0': {
              id: champ_multiple_drop_down_list.id,
              value: ['', 'un', 'deux']
            },
            '1': {
              id: champ_datetime.id,
              'value(1i)': 2019,
              'value(2i)': 12,
              'value(3i)': 21,
              'value(4i)': 13,
              'value(5i)': 17
            }
          }
        }
      }

      champ_multiple_drop_down_list.reload
      champ_datetime.reload
    end

    it { expect(champ_multiple_drop_down_list.value).to eq('["un", "deux"]') }
    it { expect(champ_datetime.value).to eq('21/12/2019 13:17') }
    it { expect(response).to redirect_to(annotations_privees_gestionnaire_dossier_path(dossier.procedure, dossier)) }
  end
end
