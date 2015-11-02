require 'rails_helper'

describe Backoffice::DossiersController, type: :controller do
  let(:dossier) { create(:dossier, :with_entreprise, :with_user) }
  let(:dossier_id) { dossier.id }
  let(:bad_dossier_id) { Dossier.count + 10 }
  let(:gestionnaire) { create(:gestionnaire) }

  describe 'GET #show' do
    context "l'utilisateur est connecté" do
      before do
        sign_in gestionnaire
      end

      it 'returns http success' do
        get :show, id: dossier_id
        expect(response).to have_http_status(200)
      end

      it "le numéro de dossier n'existe pas" do
        get :show, id: bad_dossier_id
        expect(response).to redirect_to('/backoffice')
      end
    end

    context "L'utilisateur n'est pas connecté mais le numéro de dossier est correct" do
      subject { get :show, id: dossier_id }
      it { is_expected.to redirect_to('/gestionnaires/sign_in') }
    end
  end

  describe 'POST #confirme' do
    context 'le gestionnaire valide un dossier' do
      before do
        dossier.submitted!
        sign_in gestionnaire
      end

      it 'dossier change is state for confirmed' do
        post :confirme, dossier_id: dossier_id

        dossier.reload
        expect(dossier.state).to eq('confirmed')
      end
    end
  end

  describe 'POST #process_end' do
    context 'le gestionnaire taite un dossier' do
      before do
        dossier.deposited!
        sign_in gestionnaire
      end

      it 'dossier change is state for processed' do
        post :process_end, dossier_id: dossier_id

        dossier.reload
        expect(dossier.state).to eq('processed')
      end
    end
  end
end
