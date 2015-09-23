require 'spec_helper'

RSpec.describe DossiersController, type: :controller do
  let(:dossier) { create(:dossier, :with_entreprise, :with_procedure) }
  let(:dossier_id) { dossier.id }
  let(:siret_not_found) { 999_999_999_999 }

  let(:siren) { dossier.siren }
  let(:siret) { dossier.siret }
  let(:bad_siret) { 1 }

  describe 'GET #show' do
    it 'returns http success with dossier_id valid' do
      get :show, id: dossier_id
      expect(response).to have_http_status(:success)
    end

    it 'redirection vers start si mauvais dossier ID' do
      get :show, id: siret_not_found
      expect(response).to redirect_to('/start/error_dossier')
    end
  end

  describe 'POST #create' do
    before do
      stub_request(:get, "https://api-dev.apientreprise.fr/api/v1/etablissements/#{siret_not_found}?token=#{SIADETOKEN}")
        .to_return(status: 404, body: 'fake body')

      stub_request(:get, "https://api-dev.apientreprise.fr/api/v1/etablissements/#{siret}?token=#{SIADETOKEN}")
        .to_return(status: 200, body: File.read('spec/support/files/etablissement.json'))

      stub_request(:get, "https://api-dev.apientreprise.fr/api/v1/entreprises/#{siren}?token=#{SIADETOKEN}")
        .to_return(status: 200, body: File.read('spec/support/files/entreprise.json'))
    end

    describe 'professionnel fills form' do
      context 'when pro_dossier_id is empty' do
        context 'with valid siret ' do
          before do
            post :create, siret: siret, pro_dossier_id: '', procedure_id: Procedure.last
          end

          it 'create a dossier' do
            expect { post :create, siret: siret, pro_dossier_id: '' }.to change { Dossier.count }.by(1)
          end

          it 'creates entreprise' do
            expect { post :create, siret: siret, pro_dossier_id: '', procedure_id: Procedure.last }.to change { Entreprise.count }.by(1)
          end

          it 'links entreprise to dossier' do
            expect(Entreprise.last.dossier).to eq(Dossier.last)
          end

          it 'creates etablissement for dossier' do
            expect { post :create, siret: siret, pro_dossier_id: '', procedure_id: Procedure.last }.to change { Etablissement.count }.by(1)
          end

          it 'links etablissement to dossier' do
            expect(Etablissement.last.dossier).to eq(Dossier.last)
          end

          it 'links etablissement to entreprise' do
            expect(Etablissement.last.entreprise).to eq(Entreprise.last)
          end

          it 'links procedure to dossier' do
            expect(Dossier.last.procedure).to eq(Procedure.last)
          end

          it 'state of dossier is draft' do
            expect(Dossier.last.state).to eq('draft')
          end
        end

        context 'with non existant siret' do
          let(:siret_not_found) { '11111111111111' }
          subject { post :create, siret: siret_not_found, pro_dossier_id: '' }
          it 'does not create new dossier' do
            expect { subject }.not_to change { Dossier.count }
          end

          it 'redirects to show' do
            expect(subject).to redirect_to(controller: :start, action: :error_siret)
          end
        end
      end
    end
  end

  describe 'PUT #update' do
    before do
      put :update, id: dossier_id, dossier: { autorisation_donnees: autorisation_donnees }
    end
    context 'when Checkbox is checked' do
      let(:autorisation_donnees) { '1' }
      it 'redirects to demande' do
        expect(response).to redirect_to(controller: :description, action: :show, dossier_id: dossier.id)
      end

      it 'update dossier' do
        dossier.reload
        expect(dossier.autorisation_donnees).to be_truthy
      end
    end

    context 'when Checkbox is not checked' do
      let(:autorisation_donnees) { '0' }
      it 'uses flash alert to display message' do
        expect(flash[:alert]).to have_content('Les conditions sont obligatoires.')
      end

      it "doesn't update dossier autorisation_donnees" do
        dossier.reload
        expect(dossier.autorisation_donnees).to be_falsy
      end
    end
  end
end
