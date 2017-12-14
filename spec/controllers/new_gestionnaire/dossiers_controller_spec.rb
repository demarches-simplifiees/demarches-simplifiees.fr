require 'spec_helper'

describe NewGestionnaire::DossiersController, type: :controller do
  render_views

  let(:gestionnaire) { create(:gestionnaire) }
  let(:procedure) { create(:procedure, :published, gestionnaires: [gestionnaire]) }
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
            controller.render nothing: true
          end

        get :attestation, params: { procedure_id: procedure.id, dossier_id: dossier.id }
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe '#follow' do
    before do
      expect_any_instance_of(Dossier).to receive(:next_step!).with('gestionnaire', 'follow')
      patch :follow, params: { procedure_id: procedure.id, dossier_id: dossier.id }
    end

    it { expect(gestionnaire.followed_dossiers).to match([dossier]) }
    it { expect(flash.notice).to eq('Dossier suivi') }
    it { expect(response).to redirect_to(procedures_url) }
  end

  describe '#unfollow' do
    before do
      gestionnaire.followed_dossiers << dossier
      patch :unfollow, params: { procedure_id: procedure.id, dossier_id: dossier.id }
      gestionnaire.reload
    end

    it { expect(gestionnaire.followed_dossiers).to match([]) }
    it { expect(flash.notice).to eq("Vous ne suivez plus le dossier nº #{dossier.id}") }
    it { expect(response).to redirect_to(procedures_url) }
  end

  describe '#archive' do
    before do
      gestionnaire.follow(dossier)
      patch :archive, params: { procedure_id: procedure.id, dossier_id: dossier.id }
      dossier.reload
      gestionnaire.reload
    end

    it { expect(dossier.archived).to be true }
    it { expect(response).to redirect_to(procedures_url) }
    it { expect(gestionnaire.followed_dossiers).not_to include(dossier) }
  end

  describe '#unarchive' do
    before do
      dossier.update_attributes(archived: true)
      patch :unarchive, params: { procedure_id: procedure.id, dossier_id: dossier.id }
      dossier.reload
    end

    it { expect(dossier.archived).to be false }
    it { expect(response).to redirect_to(procedures_url) }
  end

  describe '#passer_en_instruction' do
    before do
      dossier.en_construction!
      sign_in gestionnaire
      post :passer_en_instruction, params: { procedure_id: procedure.id, dossier_id: dossier.id }
      dossier.reload
    end

    it { expect(dossier.state).to eq('received') }
    it { is_expected.to redirect_to dossier_path(procedure, dossier) }
    it { expect(gestionnaire.follow?(dossier)).to be true }
  end

  describe '#repasser_en_construction' do
    before do
      dossier.received!
      sign_in gestionnaire
    end

    subject { post :repasser_en_construction, params: { procedure_id: procedure.id, dossier_id: dossier.id} }

    it 'change state to en_construction' do
      subject

      dossier.reload
      expect(dossier.state).to eq('en_construction')
    end

    it { is_expected.to redirect_to dossier_path(procedure, dossier) }
  end

  describe '#terminer' do
    context "with refuser" do
      before do
        dossier.received!
        sign_in gestionnaire
      end

      subject { post :terminer, params: { process_action: "refuser", procedure_id: procedure.id, dossier_id: dossier.id} }

      it 'change state to refused' do
        subject

        dossier.reload
        expect(dossier.state).to eq('refused')
      end

      it 'Notification email is sent' do
        expect(NotificationMailer).to receive(:send_notification)
          .with(dossier, kind_of(Mails::RefusedMail), nil).and_return(NotificationMailer)
        expect(NotificationMailer).to receive(:deliver_now!)

        subject
      end

      it { is_expected.to redirect_to redirect_to dossier_path(procedure, dossier) }
    end

    context "with classer_sans_suite" do
      before do
        dossier.received!
        sign_in gestionnaire
      end

      subject { post :terminer, params: { process_action: "classer_sans_suite", procedure_id: procedure.id, dossier_id: dossier.id} }

      it 'change state to without_continuation' do
        subject

        dossier.reload
        expect(dossier.state).to eq('without_continuation')
      end

      it 'Notification email is sent' do
        expect(NotificationMailer).to receive(:send_notification)
          .with(dossier, kind_of(Mails::WithoutContinuationMail), nil).and_return(NotificationMailer)
        expect(NotificationMailer).to receive(:deliver_now!)

        subject
      end

      it { is_expected.to redirect_to redirect_to dossier_path(procedure, dossier) }
    end

    context "with accepter" do
      let(:expected_attestation) { nil }

      before do
        dossier.received!
        sign_in gestionnaire

        expect(NotificationMailer).to receive(:send_notification)
          .with(dossier, kind_of(Mails::ClosedMail), expected_attestation)
          .and_return(NotificationMailer)

        expect(NotificationMailer).to receive(:deliver_now!)
      end

      subject { post :terminer, params: { process_action: "accepter", procedure_id: procedure.id, dossier_id: dossier.id} }

      it 'change state to closed' do
        subject

        dossier.reload
        expect(dossier.state).to eq('closed')
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

            is_expected.to redirect_to redirect_to dossier_path(procedure, dossier)
          end
        end

        context 'when the dossier has an attestation not emailable' do
          let(:emailable) { false }
          let(:expected_attestation) { nil }

          it 'Notification email is sent without the attestation' do
            expect(controller).to receive(:capture_message)

            subject

            is_expected.to redirect_to redirect_to dossier_path(procedure, dossier)
          end
        end
      end
    end
  end

  describe '#show #messagerie #annotations_privees #avis' do
    before do
      dossier.notifications = %w(champs annotations_privees avis commentaire).map{ |type| Notification.create!(type_notif: type) }
      get method, params: { procedure_id: procedure.id, dossier_id: dossier.id }
      dossier.notifications.each(&:reload)
    end

    context '#show' do
      let(:method) { :show }
      it { expect(dossier.notifications.map(&:already_read)).to match([true, false, false, false]) }
      it { expect(response).to have_http_status(:success) }
    end

    context '#annotations_privees' do
      let(:method) { :annotations_privees }
      it { expect(dossier.notifications.map(&:already_read)).to match([false, true, false, false]) }
      it { expect(response).to have_http_status(:success) }
    end

    context '#avis' do
      let(:method) { :avis }
      it { expect(dossier.notifications.map(&:already_read)).to match([false, false, true, false]) }
      it { expect(response).to have_http_status(:success) }
    end

    context '#messagerie' do
      let(:method) { :messagerie }
      it { expect(dossier.notifications.map(&:already_read)).to match([false, false, false, true]) }
      it { expect(response).to have_http_status(:success) }
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
      expect(response).to redirect_to(messagerie_dossier_path(dossier.procedure, dossier))
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

    before do
      post :create_avis, params: {
        procedure_id: procedure.id,
        dossier_id: dossier.id,
        avis: { email: 'email@a.com', introduction: 'intro', confidentiel: true }
      }
    end

    it { expect(saved_avis.email).to eq('email@a.com') }
    it { expect(saved_avis.introduction).to eq('intro') }
    it { expect(saved_avis.confidentiel).to eq(true) }
    it { expect(saved_avis.dossier).to eq(dossier) }
    it { expect(saved_avis.claimant).to eq(gestionnaire) }
    it { expect(response).to redirect_to(avis_dossier_path(dossier.procedure, dossier)) }
  end

  describe "#update_annotations" do
    let(:champ_multiple_drop_down_list) do
      type_de_champ = TypeDeChamp.create(type_champ: 'multiple_drop_down_list', libelle: 'libelle')
      ChampPrivate.create(type_de_champ: type_de_champ)
    end

    let(:champ_datetime) do
      type_de_champ = TypeDeChamp.create(type_champ: 'datetime', libelle: 'libelle')
      ChampPrivate.create(type_de_champ: type_de_champ)
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
    it { expect(response).to redirect_to(annotations_privees_dossier_path(dossier.procedure, dossier)) }
  end
end
