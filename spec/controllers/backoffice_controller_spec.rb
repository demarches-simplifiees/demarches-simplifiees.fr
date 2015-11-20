require 'spec_helper'

describe BackofficeController, type: :controller do
  describe 'GET #index' do
    context 'when gestionnaire is not connected'do
      before do
        get :index
      end

      it { expect(response).to redirect_to :new_gestionnaire_session }
    end

    context 'when gestionnaire is connected'do
      before do
        sign_in create(:gestionnaire)
        get :index
      end

      it { expect(response).to redirect_to :backoffice_dossiers_a_traiter }
    end
  end
end