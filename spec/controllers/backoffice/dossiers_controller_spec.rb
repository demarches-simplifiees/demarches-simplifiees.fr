require 'rails_helper'

describe Backoffice::DossiersController, type: :controller do
  before do
    @request.env['HTTP_REFERER'] =  TPS::Application::URL
  end

  let(:dossier) { create(:dossier, :with_entreprise) }
  let(:dossier_archived) { create(:dossier, :with_entreprise, archived: true) }

  let(:dossier_id) { dossier.id }
  let(:bad_dossier_id) { Dossier.count + 10 }
  let(:gestionnaire) { create(:gestionnaire, administrateurs: [create(:administrateur)]) }

  describe 'GET #show' do
    context 'gestionnaire is connected' do
      before do
        sign_in gestionnaire
      end

      it 'returns http success' do
        get :show, id: dossier_id
        expect(response).to have_http_status(200)
      end

      context ' when dossier is archived' do
        before do
          get :show, id: dossier_archived.id
        end
        it { expect(response).to redirect_to('/backoffice') }
      end

      context 'when dossier id does not exist' do
        before do
          get :show, id: bad_dossier_id
        end
        it { expect(response).to redirect_to('/backoffice') }
      end
    end

    context 'gestionnaire does not connected but dossier id is correct' do
      subject { get :show, id: dossier_id }

      it { is_expected.to redirect_to('/gestionnaires/sign_in') }
    end
  end

  describe 'GET #a_traiter' do
    context 'when gestionnaire is connected' do
      before do
        sign_in gestionnaire
      end

      it 'returns http success' do
        get :index, liste: :a_traiter
        expect(response).to have_http_status(200)
      end
    end
  end

  describe 'GET #en_attente' do
    context 'when gestionnaire is connected' do
      before do
        sign_in gestionnaire
      end

      it 'returns http success' do
        get :index, liste: :en_attente
        expect(response).to have_http_status(200)
      end
    end
  end

  describe 'GET #termine' do
    context 'when gestionnaire is connected' do
      before do
        sign_in gestionnaire
      end

      it 'returns http success' do
        get :index, liste: :termine
        expect(response).to have_http_status(200)
      end
    end
  end

  describe 'POST #search' do
    before do
      sign_in gestionnaire
    end

    it 'returns http success' do
      post :search, search_terms: 'test'
      expect(response).to have_http_status(200)
    end

  end

  describe 'POST #valid' do
    before do
      dossier.initiated!
      sign_in gestionnaire
    end

    subject { post :valid, dossier_id: dossier_id }

    it 'change state to validated' do
      subject

      dossier.reload
      expect(dossier.state).to eq('validated')
    end

    it 'Notification email is send' do
      expect(NotificationMailer).to receive(:dossier_validated).and_return(NotificationMailer)
      expect(NotificationMailer).to receive(:deliver_now!)

      subject
    end
  end

  describe 'POST #receive' do
    before do
      dossier.submitted!
      sign_in gestionnaire
    end

    it 'change state to received' do
      post :receive, dossier_id: dossier_id

      dossier.reload
      expect(dossier.state).to eq('received')
    end
  end

  describe 'POST #close' do
    before do
      dossier.received!
      sign_in gestionnaire
    end

    it 'change state to closed' do
      post :close, dossier_id: dossier_id

      dossier.reload
      expect(dossier.state).to eq('closed')
    end
  end

  describe 'PUT #toggle_follow' do
    before do
      sign_in gestionnaire
    end

    subject { put :follow, dossier_id: dossier_id }

    it { expect(subject.status).to eq 302 }

    describe 'flash alert' do
      context 'when dossier is not follow by gestionnaire' do
        before do
          subject
        end
        it { expect(flash[:notice]).to have_content 'Dossier suivi' }
      end

      context 'when dossier is follow by gestionnaire' do
        before do
          create :follow, gestionnaire_id: gestionnaire.id, dossier_id: dossier.id
          subject
        end
        it { expect(flash[:notice]).to have_content 'Dossier relaché' }
      end
    end
  end
end
