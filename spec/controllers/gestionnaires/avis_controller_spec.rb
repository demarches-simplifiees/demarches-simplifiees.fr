require 'spec_helper'

describe Gestionnaires::AvisController, type: :controller do
  context 'with a gestionnaire signed in' do
    render_views

    let(:claimant) { create(:gestionnaire) }
    let(:gestionnaire) { create(:gestionnaire) }
    let(:procedure) { create(:procedure, :published, gestionnaires: [gestionnaire]) }
    let(:dossier) { create(:dossier, :en_construction, procedure: procedure) }
    let!(:avis_without_answer) { Avis.create(dossier: dossier, claimant: claimant, gestionnaire: gestionnaire) }
    let!(:avis_with_answer) { Avis.create(dossier: dossier, claimant: claimant, gestionnaire: gestionnaire, answer: 'yop') }

    before { sign_in(gestionnaire) }

    describe '#index' do
      before { get :index }

      it { expect(response).to have_http_status(:success) }
      it { expect(assigns(:avis_a_donner)).to match([avis_without_answer]) }
      it { expect(assigns(:avis_donnes)).to match([avis_with_answer]) }
      it { expect(assigns(:statut)).to eq('a-donner') }

      context 'with a statut equal to donnes' do
        before { get :index, params: { statut: 'donnes' } }

        it { expect(assigns(:statut)).to eq('donnes') }
      end
    end

    describe '#show' do
      before { get :show, params: { id: avis_without_answer.id } }

      it { expect(response).to have_http_status(:success) }
      it { expect(assigns(:avis)).to eq(avis_without_answer) }
      it { expect(assigns(:dossier)).to eq(dossier) }
    end

    describe '#instruction' do
      before { get :instruction, params: { id: avis_without_answer.id } }

      it { expect(response).to have_http_status(:success) }
      it { expect(assigns(:avis)).to eq(avis_without_answer) }
      it { expect(assigns(:dossier)).to eq(dossier) }
    end

    describe '#messagerie' do
      before { get :messagerie, params: { id: avis_without_answer.id } }

      it { expect(response).to have_http_status(:success) }
      it { expect(assigns(:avis)).to eq(avis_without_answer) }
      it { expect(assigns(:dossier)).to eq(dossier) }
    end

    describe '#update' do
      before do
        patch :update, params: { id: avis_without_answer.id, avis: { answer: 'answer' } }
        avis_without_answer.reload
      end

      it { expect(response).to redirect_to(instruction_gestionnaire_avis_path(avis_without_answer)) }
      it { expect(avis_without_answer.answer).to eq('answer') }
      it { expect(flash.notice).to eq('Votre réponse est enregistrée.') }
    end

    describe '#create_commentaire' do
      let(:file) { nil }
      let(:scan_result) { true }

      subject { post :create_commentaire, params: { id: avis_without_answer.id, commentaire: { body: 'commentaire body', file: file } } }

      before do
        allow(ClamavService).to receive(:safe_file?).and_return(scan_result)
      end

      it do
        subject

        expect(response).to redirect_to(messagerie_gestionnaire_avis_path(avis_without_answer))
        expect(dossier.commentaires.map(&:body)).to match(['commentaire body'])
      end

      context "with a file" do
        let(:file) { Rack::Test::UploadedFile.new("./spec/fixtures/files/piece_justificative_0.pdf", 'application/pdf') }

        it do
          subject
          expect(Commentaire.last.file.path).to include("piece_justificative_0.pdf")
        end

        it { expect { subject }.to change(Commentaire, :count).by(1) }

        context "and a virus" do
          let(:scan_result) { false }

          it { expect { subject }.not_to change(Commentaire, :count) }
        end
      end
    end

    describe '#create_avis' do
      let!(:previous_avis) { Avis.create(dossier: dossier, claimant: claimant, gestionnaire: gestionnaire, confidentiel: previous_avis_confidentiel) }
      let(:emails) { ['a@b.com'] }
      let(:intro) { 'introduction' }
      let(:created_avis) { Avis.last }
      let!(:old_avis_count) { Avis.count }

      before do
        post :create_avis, params: { id: previous_avis.id, avis: { emails: emails, introduction: intro, confidentiel: asked_confidentiel } }
      end

      context 'when an invalid email' do
        let(:previous_avis_confidentiel) { false }
        let(:asked_confidentiel) { false }
        let(:emails) { ["toto.fr"] }

        it { expect(response).to render_template :instruction }
        it { expect(flash.alert).to eq(["toto.fr : Email n'est pas valide"]) }
        it { expect(Avis.last).to eq(previous_avis) }
      end

      context 'with multiple emails' do
        let(:asked_confidentiel) { false }
        let(:previous_avis_confidentiel) { false }
        let(:emails) { ["toto.fr,titi@titimail.com"] }

        it { expect(response).to render_template :instruction }
        it { expect(flash.alert).to eq(["toto.fr : Email n'est pas valide"]) }
        it { expect(flash.notice).to eq("Une demande d'avis a été envoyée à titi@titimail.com") }
        it { expect(Avis.count).to eq(old_avis_count + 1) }
        it { expect(created_avis.email).to eq("titi@titimail.com") }
      end

      context 'when the previous avis is public' do
        let(:previous_avis_confidentiel) { false }

        context 'when the user asked for a public avis' do
          let(:asked_confidentiel) { false }

          it { expect(created_avis.confidentiel).to be(false) }
          it { expect(created_avis.email).to eq(emails.last) }
          it { expect(created_avis.introduction).to eq(intro) }
          it { expect(created_avis.dossier).to eq(previous_avis.dossier) }
          it { expect(created_avis.claimant).to eq(gestionnaire) }
          it { expect(response).to redirect_to(instruction_gestionnaire_avis_path(previous_avis)) }
        end

        context 'when the user asked for a confidentiel avis' do
          let(:asked_confidentiel) { true }

          it { expect(created_avis.confidentiel).to be(true) }
        end
      end

      context 'when the preivous avis is confidentiel' do
        let(:previous_avis_confidentiel) { true }

        context 'when the user asked for a public avis' do
          let(:asked_confidentiel) { false }

          it { expect(created_avis.confidentiel).to be(true) }
        end
      end
    end
  end

  context 'without a gestionnaire signed in' do
    describe '#sign_up' do
      let(:invited_email) { 'invited@avis.com' }
      let(:dossier) { create(:dossier) }
      let!(:avis) { create(:avis, email: invited_email, dossier: dossier) }
      let(:invitations_email) { true }

      context 'when the new gestionnaire has never signed up' do
        before do
          expect(Avis).to receive(:avis_exists_and_email_belongs_to_avis?)
            .with(avis.id.to_s, invited_email)
            .and_return(invitations_email)
          get :sign_up, params: { id: avis.id, email: invited_email }
        end

        context 'when the email belongs to the invitation' do
          it { expect(subject.status).to eq(200) }
          it { expect(assigns(:email)).to eq(invited_email) }
          it { expect(assigns(:dossier)).to eq(dossier) }
        end

        context 'when the email does not belong to the invitation' do
          let(:invitations_email) { false }

          it { is_expected.to redirect_to root_path }
        end
      end

      context 'when the gestionnaire has already signed up and belongs to the invitation' do
        let(:gestionnaire) { create(:gestionnaire, email: invited_email) }
        let!(:avis) { create(:avis, dossier: dossier, gestionnaire: gestionnaire) }

        context 'when the gestionnaire is authenticated' do
          before do
            sign_in gestionnaire
            get :sign_up, params: { id: avis.id, email: invited_email }
          end

          it { is_expected.to redirect_to gestionnaire_avis_url(avis) }
        end

        context 'when the gestionnaire is not authenticated' do
          before do
            get :sign_up, params: { id: avis.id, email: invited_email }
          end

          it { is_expected.to redirect_to new_gestionnaire_session_url }
        end
      end

      context 'when the gestionnaire has already signed up / is authenticated and does not belong to the invitation' do
        let(:gestionnaire) { create(:gestionnaire, email: 'other@gmail.com') }
        let!(:avis) { create(:avis, email: invited_email, dossier: dossier) }

        before do
          sign_in gestionnaire
          get :sign_up, params: { id: avis.id, email: invited_email }
        end

        # redirected to dossier but then the gestionnaire gonna be banished !
        it { is_expected.to redirect_to gestionnaire_avis_url(avis) }
      end
    end

    describe '#create_gestionnaire' do
      let(:existing_user_mail) { 'dummy@example.org' }
      let!(:existing_user) { create(:user, email: existing_user_mail) }
      let(:invited_email) { 'invited@avis.com' }
      let(:dossier) { create(:dossier) }
      let!(:avis) { create(:avis, email: invited_email, dossier: dossier) }
      let(:avis_id) { avis.id }
      let(:password) { '12345678' }
      let(:created_gestionnaire) { Gestionnaire.find_by(email: invited_email) }
      let(:invitations_email) { true }

      before do
        allow(Avis).to receive(:link_avis_to_gestionnaire)
        expect(Avis).to receive(:avis_exists_and_email_belongs_to_avis?)
          .with(avis_id.to_s, invited_email)
          .and_return(invitations_email)

        post :create_gestionnaire, params: {
          id: avis_id,
          email: invited_email,
          gestionnaire: {
            password: password
          }
        }
      end

      context 'when the email does not belong to the invitation' do
        let(:invitations_email) { false }

        it { is_expected.to redirect_to root_path }
      end

      context 'when the email belongs to the invitation' do
        context 'when the gestionnaire creation succeeds' do
          it { expect(created_gestionnaire).to be_present }
          it { expect(created_gestionnaire.valid_password?(password)).to be true }

          it { expect(Avis).to have_received(:link_avis_to_gestionnaire) }

          it { expect(subject.current_gestionnaire).to eq(created_gestionnaire) }
          it { is_expected.to redirect_to gestionnaire_avis_index_path }

          it 'creates a corresponding user account for the email' do
            user = User.find_by(email: invited_email)
            expect(user).to be_present
          end

          context 'when there already is a user account with the same email' do
            let(:existing_user_mail) { invited_email }

            it 'still creates a gestionnaire account' do
              expect(created_gestionnaire).to be_present
            end
          end
        end

        context 'when the gestionnaire creation fails' do
          let(:password) { '' }

          it { expect(created_gestionnaire).to be_nil }
          it { is_expected.to redirect_to sign_up_gestionnaire_avis_path(avis_id, invited_email) }
          it { expect(flash.alert).to eq(['Le mot de passe doit être rempli']) }
        end
      end
    end
  end
end
