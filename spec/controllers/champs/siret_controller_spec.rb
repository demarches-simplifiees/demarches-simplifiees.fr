require 'spec_helper'

describe Champs::SiretController, type: :controller do
  let(:user) { create(:user) }
  let(:procedure) { create(:procedure, :published) }

  describe '#show' do
    let(:dossier) { create(:dossier, user: user, procedure: procedure) }
    let(:champ) { create(:champ_siret, dossier: dossier, value: nil, etablissement: nil) }
    let(:params) do
      {
        champ_id: champ.id,
        dossier: {
          champs_attributes: {
            '1' => { value: siret.to_s }
          }
        },
        position: '1'
      }
    end
    let(:siret) { '' }

    context 'when user is connected' do
      render_views
      before { sign_in user }

      context 'when siret empty' do
        before {
          get :show, params: params, format: 'js'
        }

        it 'empty info message' do
          expect(response.body).to include('.siret-info-1')
          expect(response.body).to include('innerHTML = ""')
          champ.reload
          expect(champ.etablissement).to be_nil
          expect(champ.value).to be_empty
        end
      end

      context 'when siret invalid' do
        let(:siret) { '1234' }
        before {
          get :show, params: params, format: 'js'
        }

        it 'invalid error' do
          expect(response.body).to include("Le numéro TAHITI doit comporter exactement #{SIRET_LENGTH} caractères.")
          champ.reload
          expect(champ.etablissement).to be_nil
          expect(champ.value).to be_empty
        end
      end

      context 'when siret not found' do
        let(:siret) { '0' * SIRET_LENGTH }
        before {
          expect(subject).to receive(:find_etablisement_with_siret).and_return(false)
          get :show, params: params, format: 'js'
        }

        it 'not found error' do
          expect(response.body).to include("Nous n’avons pas trouvé d’établissement correspondant à ce numéro TAHITI.")
          champ.reload
          expect(champ.etablissement).to be_nil
          expect(champ.value).to be_empty
        end
      end

      context 'when siret found' do
        let(:siret) { etablissement.siret }
        let(:etablissement) { build(:etablissement) }
        before {
          expect(subject).to receive(:find_etablisement_with_siret).and_return(etablissement)
          get :show, params: params, format: 'js'
        }

        it 'etablissement info message' do
          expect(response.body).to include(etablissement.entreprise_raison_sociale)
          champ.reload
          expect(champ.value).to eq(etablissement.siret)
          expect(champ.etablissement.siret).to eq(etablissement.siret)
        end
      end
    end

    context 'when user is not connected' do
      before {
        get :show, params: { position: '1' }, format: 'js'
      }

      it { expect(response.code).to eq('401') }
    end
  end
end
