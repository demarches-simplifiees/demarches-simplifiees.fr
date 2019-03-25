require 'spec_helper'

describe Gestionnaires::DossiersController, type: :controller do
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

  describe '#send_to_instructeurs' do
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
        :send_to_instructeurs,
        params: {
          recipients: [recipient],
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
      post :passer_en_instruction, params: { procedure_id: procedure.id, dossier_id: dossier.id }, format: 'js'
      dossier.reload
    end

    it { expect(dossier.state).to eq(Dossier.states.fetch(:en_instruction)) }
    it { expect(response.body).to include('.state-button') }
    it { expect(gestionnaire.follow?(dossier)).to be true }
  end

  describe '#repasser_en_construction' do
    before do
      dossier.en_instruction!
      sign_in gestionnaire
    end

    subject { post :repasser_en_construction, params: { procedure_id: procedure.id, dossier_id: dossier.id }, format: 'js' }

    it 'change state to en_construction' do
      subject

      dossier.reload
      expect(dossier.state).to eq(Dossier.states.fetch(:en_construction))
    end

    it { expect(subject.body).to include('.state-button') }
  end

  describe '#terminer' do
    context "with refuser" do
      before do
        dossier.en_instruction!
        sign_in gestionnaire
      end

      subject { post :terminer, params: { process_action: "refuser", procedure_id: procedure.id, dossier_id: dossier.id }, format: 'js' }

      it 'change state to refuse' do
        subject

        dossier.reload
        expect(dossier.state).to eq(Dossier.states.fetch(:refuse))
      end

      it 'Notification email is sent' do
        expect(NotificationMailer).to receive(:send_refused_notification)
          .with(dossier).and_return(NotificationMailer)
        expect(NotificationMailer).to receive(:deliver_later)

        subject
      end

      it { expect(subject.body).to include('.state-button') }
    end

    context "with classer_sans_suite" do
      before do
        dossier.en_instruction!
        sign_in gestionnaire
      end

      subject { post :terminer, params: { process_action: "classer_sans_suite", procedure_id: procedure.id, dossier_id: dossier.id }, format: 'js' }

      it 'change state to sans_suite' do
        subject

        dossier.reload
        expect(dossier.state).to eq(Dossier.states.fetch(:sans_suite))
      end

      it 'Notification email is sent' do
        expect(NotificationMailer).to receive(:send_without_continuation_notification)
          .with(dossier).and_return(NotificationMailer)
        expect(NotificationMailer).to receive(:deliver_later)

        subject
      end

      it { expect(subject.body).to include('.state-button') }
    end

    context "with accepter" do
      before do
        dossier.en_instruction!
        sign_in gestionnaire

        expect(NotificationMailer).to receive(:send_closed_notification)
          .with(dossier)
          .and_return(NotificationMailer)

        expect(NotificationMailer).to receive(:deliver_later)
      end

      subject { post :terminer, params: { process_action: "accepter", procedure_id: procedure.id, dossier_id: dossier.id }, format: 'js' }

      it 'change state to accepte' do
        subject

        dossier.reload
        expect(dossier.state).to eq(Dossier.states.fetch(:accepte))
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

          allow_any_instance_of(Dossier).to receive(:build_attestation).and_return(attestation)
        end

        it 'The gestionnaire is sent back to the dossier page' do
          expect(subject.body).to include('.state-button')
        end

        context 'and the dossier has already an attestation' do
          it 'should not crash' do
            dossier.attestation = Attestation.new
            dossier.save
            expect(subject.body).to include('.state-button')
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
          }, format: 'js'
        end

        before do
          Timecop.freeze(Time.zone.now)

          expect_any_instance_of(AttestationTemplate)
            .to receive(:attestation_for)
            .with(have_attributes(motivation: "Yallah", processed_at: Time.zone.now))
        end

        after { Timecop.return }

        it { subject }
      end
    end
  end

  describe "#create_commentaire" do
    let(:saved_commentaire) { dossier.commentaires.first }
    let(:body) { "avant\napres" }
    let(:file) { Rack::Test::UploadedFile.new("./spec/fixtures/files/piece_justificative_0.pdf", 'application/pdf') }
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

    it "creates a commentaire" do
      expect { subject }.to change(Commentaire, :count).by(1)
      expect(gestionnaire.followed_dossiers).to include(dossier)

      expect(response).to redirect_to(messagerie_gestionnaire_dossier_path(dossier.procedure, dossier))
      expect(flash.notice).to be_present
    end

    context "when the commentaire creation fails" do
      let(:scan_result) { false }

      it "renders the messagerie page with the invalid commentaire" do
        expect { subject }.not_to change(Commentaire, :count)

        expect(response).to render_template :messagerie
        expect(flash.alert).to be_present
        expect(assigns(:commentaire).body).to eq("avant\napres")
      end
    end
  end

  describe "#create_avis" do
    let(:saved_avis) { dossier.avis.first }
    let!(:old_avis_count) { Avis.count }

    subject do
      post :create_avis, params: {
        procedure_id: procedure.id,
        dossier_id: dossier.id,
        avis: { emails: emails, introduction: 'intro', confidentiel: true }
      }
    end

    before do
      subject
    end

    let(:emails) { ['email@a.com'] }

    it { expect(saved_avis.email).to eq('email@a.com') }
    it { expect(saved_avis.introduction).to eq('intro') }
    it { expect(saved_avis.confidentiel).to eq(true) }
    it { expect(saved_avis.dossier).to eq(dossier) }
    it { expect(saved_avis.claimant).to eq(gestionnaire) }
    it { expect(response).to redirect_to(avis_gestionnaire_dossier_path(dossier.procedure, dossier)) }

    context "with an invalid email" do
      let(:emails) { ['emaila.com'] }

      it { expect(response).to render_template :avis }
      it { expect(flash.alert).to eq(["emaila.com : Email n'est pas valide"]) }
      it { expect { subject }.not_to change(Avis, :count) }
    end

    context 'with multiple emails' do
      let(:emails) { ["toto.fr,titi@titimail.com"] }

      it { expect(response).to render_template :avis }
      it { expect(flash.alert).to eq(["toto.fr : Email n'est pas valide"]) }
      it { expect(flash.notice).to eq("Une demande d'avis a été envoyée à titi@titimail.com") }
      it { expect(Avis.count).to eq(old_avis_count + 1) }
      it { expect(saved_avis.email).to eq("titi@titimail.com") }
    end
  end

  describe "#update_annotations" do
    let(:champ_multiple_drop_down_list) do
      create(:type_de_champ_multiple_drop_down_list, :private, libelle: 'libelle').champ.create
    end

    let(:champ_linked_drop_down_list) do
      create(:type_de_champ_linked_drop_down_list, :private, libelle: 'libelle').champ.create
    end

    let(:champ_datetime) do
      create(:type_de_champ_datetime, :private, libelle: 'libelle').champ.create
    end

    let(:champ_repetition) do
      tdc = create(:type_de_champ_repetition, :private, libelle: 'libelle')
      tdc.types_de_champ << create(:type_de_champ_text, libelle: 'libelle')
      champ = tdc.champ.create
      champ.add_row
      champ
    end

    let(:dossier) do
      create(:dossier, :en_construction, procedure: procedure, champs_private: [champ_multiple_drop_down_list, champ_linked_drop_down_list, champ_datetime, champ_repetition])
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
            },
            '2': {
              id: champ_linked_drop_down_list.id,
              primary_value: 'primary',
              secondary_value: 'secondary'
            },
            '3': {
              id: champ_repetition.id,
              champs_attributes: {
                id: champ_repetition.champs.first.id,
                value: 'text'
              }
            }
          }
        }
      }

      champ_multiple_drop_down_list.reload
      champ_linked_drop_down_list.reload
      champ_datetime.reload
      champ_repetition.reload
    end

    it { expect(champ_multiple_drop_down_list.value).to eq('["un", "deux"]') }
    it { expect(champ_linked_drop_down_list.primary_value).to eq('primary') }
    it { expect(champ_linked_drop_down_list.secondary_value).to eq('secondary') }
    it { expect(champ_datetime.value).to eq('21/12/2019 13:17') }
    it { expect(champ_repetition.champs.first.value).to eq('text') }
    it { expect(response).to redirect_to(annotations_privees_gestionnaire_dossier_path(dossier.procedure, dossier)) }
  end

  describe '#purge_champ_piece_justificative' do
    before { sign_in(gestionnaire) }

    subject { delete :purge_champ_piece_justificative, params: { procedure_id: champ.dossier.procedure.id, dossier_id: champ.dossier.id, champ_id: champ.id }, format: :js }

    context 'when gestionnaire can process dossier' do
      let(:champ) { create(:champ_piece_justificative, dossier_id: dossier.id, private: true) }

      it { is_expected.to have_http_status(200) }

      it do
        subject
        expect(champ.reload.piece_justificative_file.attached?).to be(false)
      end

      context 'but champ is not linked to this dossier' do
        let(:champ) { create(:champ_piece_justificative, dossier: create(:dossier), private: true) }

        it { is_expected.to redirect_to(root_path) }

        it do
          subject
          expect(champ.reload.piece_justificative_file.attached?).to be(true)
        end
      end
    end

    context 'when gestionnaire cannot process dossier' do
      let(:dossier) { create(:dossier, procedure: create(:procedure)) }
      let(:champ) { create(:champ_piece_justificative, dossier_id: dossier.id, private: true) }

      it { is_expected.to redirect_to(root_path) }

      it do
        subject
        expect(champ.reload.piece_justificative_file.attached?).to be(true)
      end
    end
  end
end
