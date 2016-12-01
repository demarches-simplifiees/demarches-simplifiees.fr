require 'spec_helper'

describe Backoffice::DossiersController, type: :controller do
  before do
    @request.env['HTTP_REFERER'] = TPS::Application::URL
  end
  let(:procedure) { create :procedure }

  let(:dossier) { create(:dossier, :with_entreprise, procedure: procedure, state: :initiated) }
  let(:dossier_archived) { create(:dossier, :with_entreprise, archived: true) }

  let(:dossier_id) { dossier.id }
  let(:bad_dossier_id) { Dossier.count + 10 }
  let(:gestionnaire) { create(:gestionnaire, administrateurs: [create(:administrateur)]) }

  before do
    create :assign_to, procedure: procedure, gestionnaire: gestionnaire
  end

  describe 'GET #show' do
    context 'gestionnaire is connected' do
      before do
        sign_in gestionnaire
      end

      it 'returns http success' do
        get :show, params: {id: dossier_id}
        expect(response).to have_http_status(200)
      end

      context ' when dossier is archived' do
        before do
          get :show, params: {id: dossier_archived.id}
        end
        it { expect(response).to redirect_to('/backoffice') }
      end

      context 'when dossier id does not exist' do
        before do
          get :show, params: {id: bad_dossier_id}
        end
        it { expect(response).to redirect_to('/backoffice') }
      end
    end

    context 'gestionnaire does not connected but dossier id is correct' do
      subject { get :show, params: {id: dossier_id} }

      it { is_expected.to redirect_to('/gestionnaires/sign_in') }
    end
  end

  describe 'GET #a_traiter' do
    context 'when gestionnaire is connected' do
      before do
        sign_in gestionnaire
      end

      it 'returns http success' do
        get :index, params: {liste: :a_traiter}
        expect(response).to have_http_status(302)
      end
    end
  end

  describe 'GET #fige' do
    context 'when gestionnaire is connected' do
      before do
        sign_in gestionnaire
      end

      it 'returns http success' do
        get :index, params: {liste: :fige}
        expect(response).to have_http_status(302)
      end
    end
  end

  describe 'GET #termine' do
    context 'when gestionnaire is connected' do
      before do
        sign_in gestionnaire
      end

      it 'returns http success' do
        get :index, params: {liste: :termine}
        expect(response).to have_http_status(302)
      end
    end
  end

  describe 'GET #list_fake' do
    context 'when gestionnaire is connected' do
      before do
        sign_in gestionnaire
      end

      it 'returns http success' do
        get :index, params: {liste: :list_fake}
        expect(response).to redirect_to(backoffice_dossiers_procedure_path(id: gestionnaire.procedures.first.id))
      end
    end
  end

  describe 'POST #search' do
    before do
      sign_in gestionnaire
    end

    it 'returns http success' do
      post :search, params: {search_terms: 'test'}
      expect(response).to have_http_status(200)
    end

  end

  describe 'POST #valid' do
    before do
      dossier.initiated!
      sign_in gestionnaire
    end

    subject { post :valid, params: {dossier_id: dossier_id} }

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

    subject { post :receive, params: {dossier_id: dossier_id} }

    context 'when it post a receive instruction' do
      before do
        subject
        dossier.reload
      end

      it 'change state to received' do
        expect(dossier.state).to eq('received')
      end
    end

    it 'Notification email is send' do
      expect(NotificationMailer).to receive(:dossier_received).and_return(NotificationMailer)
      expect(NotificationMailer).to receive(:deliver_now!)

      subject
    end
  end

  describe 'POST #refuse' do
    before do
      dossier.refused!
      sign_in gestionnaire
    end

    subject { post :refuse, params: {dossier_id: dossier_id} }

    it 'change state to refused' do
      subject

      dossier.reload
      expect(dossier.state).to eq('refused')
    end

    it 'Notification email is sent' do
      expect(NotificationMailer).to receive(:dossier_refused).and_return(NotificationMailer)
      expect(NotificationMailer).to receive(:deliver_now!)

      subject
    end
  end

  describe 'POST #without_continuation' do
    before do
      dossier.without_continuation!
      sign_in gestionnaire
    end
    subject { post :without_continuation, params: {dossier_id: dossier_id} }


    it 'change state to without_continuation' do
      subject

      dossier.reload
      expect(dossier.state).to eq('without_continuation')
    end

    it 'Notification email is sent' do
      expect(NotificationMailer).to receive(:dossier_without_continuation).and_return(NotificationMailer)
      expect(NotificationMailer).to receive(:deliver_now!)

      subject
    end
  end

  describe 'POST #close' do
    before do
      dossier.received!
      sign_in gestionnaire
    end
    subject { post :close, params: {dossier_id: dossier_id} }

    it 'change state to closed' do
      subject

      dossier.reload
      expect(dossier.state).to eq('closed')
    end

    it 'Notification email is sent' do
      expect(NotificationMailer).to receive(:dossier_closed).and_return(NotificationMailer)
      expect(NotificationMailer).to receive(:deliver_now!)

      subject
    end
  end

  describe 'PUT #toggle_follow' do
    before do
      sign_in gestionnaire
    end

    subject { put :follow, params: {dossier_id: dossier_id} }

    it { expect(subject.status).to eq 302 }

    context 'when dossier is at state initiated' do
      let(:dossier) { create(:dossier, :with_entreprise, procedure: procedure, state: 'initiated') }

      before do
        subject
        dossier.reload
      end

      it 'change state for updated' do
        expect(dossier.state).to eq 'updated'
      end

    end

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
