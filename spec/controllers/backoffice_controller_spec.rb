require 'spec_helper'

describe BackofficeController, type: :controller do
  describe 'GET #index' do
    context 'when gestionnaire is not connected' do
      before do
        get :index
      end

      it { expect(response).to redirect_to :new_gestionnaire_session }
    end

    context 'when gestionnaire is connected' do
      before do
        sign_in create(:gestionnaire)
        get :index
      end

      it { expect(response).to redirect_to :backoffice_dossiers }
    end
  end

  describe 'GET #invitations' do
    context 'when gestionnaire is not invited on any dossiers' do
      render_views

      before do
        sign_in create(:gestionnaire)
        get :invitations
      end

      it { expect(response.status).to eq(200) }
      it { expect(response.body).to include("INVITATIONS") }
      it { expect(response.body).to include("0 avis à rendre") }
      it { expect(response.body).to include("0 avis rendus") }
    end

    context 'when gestionnaire is invited on a dossier' do
      let(:dossier){ create(:dossier) }
      let(:gestionnaire){ create(:gestionnaire) }
      let!(:avis){ create(:avis, dossier: dossier, gestionnaire: gestionnaire) }
      render_views

      before do
        sign_in gestionnaire
        get :invitations
      end

      it { expect(response.status).to eq(200) }
      it { expect(response.body).to include("1 avis à rendre") }
      it { expect(response.body).to include("0 avis rendus") }
      it { expect(response.body).to include(dossier.procedure.libelle) }

      context 'when avis is already sent' do
        let!(:avis){ create(:avis, dossier: dossier, gestionnaire: gestionnaire, answer: "Voici mon avis.") }

        it { expect(response.body).to include("0 avis à rendre") }
        it { expect(response.body).to include("1 avis rendu") }
        it { expect(response.body).to include(dossier.procedure.libelle) }
      end
    end
  end
end
