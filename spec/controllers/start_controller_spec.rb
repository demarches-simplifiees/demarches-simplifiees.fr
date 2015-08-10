require 'spec_helper'

RSpec.describe StartController, type: :controller do
  describe "GET #index" do
    it "returns http success" do
      get :index
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET #index with bad SIRET" do
    before do
      get :error_siret
    end

    it "returns http success and flash alert is present" do
      expect(response).to have_http_status(:success)
    end
    it 'la flash alert est présente' do
      expect(flash[:alert]).to be_present
    end
    it 'la flash alert a un libellé correct' do
      expect(flash[:alert]).to have_content('Ce SIRET n\'est pas valide')
    end
  end

  describe "GET #index with bad LOGIN" do
    before do
      get :error_login
    end

    it "returns http success and flash alert is present" do
      expect(response).to have_http_status(:success)
    end
    it 'la flash alert est présente' do
      expect(flash[:alert]).to be_present
    end
    it 'la flash alert a un libellé correct' do
      expect(flash[:alert]).to have_content('Ce compte n\'existe pas')
    end
  end

  describe "GET #index with bad DOSSIER" do
    before do
      get :error_dossier
    end

    it "returns http success and flash alert is present" do
      expect(response).to have_http_status(:success)
    end
    it 'la flash alert est présente' do
      expect(flash[:alert]).to be_present
    end
    it 'la flash alert a un libellé correct' do
      expect(flash[:alert]).to have_content('Ce dossier n\'existe pas')
    end
  end
end
