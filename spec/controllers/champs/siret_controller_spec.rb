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

    context 'when the user is signed in' do
      render_views
      before { sign_in user }

      context 'when the SIRET is empty' do
        subject! { get :show, params: params, format: 'js' }

        it 'clears the etablissement and SIRET on the model' do
          champ.reload
          expect(champ.etablissement).to be_nil
          expect(champ.value).to be_empty
        end

        it 'clears any information or error message' do
          expect(response.body).to include('.siret-info-1')
          expect(response.body).to include('innerHTML = ""')
        end
      end

      context 'when the SIRET is invalid' do
        let(:siret) { '1234' }

        subject! { get :show, params: params, format: 'js' }

        it 'clears the etablissement and SIRET on the model' do
          champ.reload
          expect(champ.etablissement).to be_nil
          expect(champ.value).to be_empty
        end

        it 'displays a “SIRET is invalid” error message' do
          expect(response.body).to include('Le numéro de SIRET doit comporter exactement 14 chiffres.')
        end
      end

      context 'when the API is unavailable' do
        let(:siret) { '82161143100015' }

        before do
          allow(controller).to receive(:find_etablissement_with_siret).and_raise(RestClient::RequestFailed)
        end

        subject! { get :show, params: params, format: 'js' }

        it 'clears the etablissement and SIRET on the model' do
          champ.reload
          expect(champ.etablissement).to be_nil
          expect(champ.value).to be_empty
        end

        it 'displays a “API is unavailable” error message' do
          expect(response.body).to include(I18n.t('errors.messages.siret_network_error'))
        end
      end

      context 'when the SIRET is valid but unknown' do
        let(:siret) { '00000000000000' }

        before do
          allow(controller).to receive(:find_etablissement_with_siret).and_return(false)
        end

        subject! { get :show, params: params, format: 'js' }

        it 'clears the etablissement and SIRET on the model' do
          champ.reload
          expect(champ.etablissement).to be_nil
          expect(champ.value).to be_empty
        end

        it 'displays a “SIRET not found” error message' do
          expect(response.body).to include('Nous n’avons pas trouvé d’établissement correspondant à ce numéro de SIRET.')
        end
      end

      context 'when the SIRET informations are retrieved successfully' do
        let(:siret) { etablissement.siret }
        let(:etablissement) { build(:etablissement) }

        before do
          allow(controller).to receive(:find_etablissement_with_siret).and_return(etablissement)
        end

        subject! { get :show, params: params, format: 'js' }

        it 'populates the etablissement and SIRET on the model' do
          champ.reload
          expect(champ.value).to eq(etablissement.siret)
          expect(champ.etablissement.siret).to eq(etablissement.siret)
        end

        it 'displays the name of the company' do
          expect(response.body).to include(etablissement.entreprise_raison_sociale)
        end
      end
    end

    context 'when user is not signed in' do
      subject! { get :show, params: { position: '1' }, format: 'js' }

      it { expect(response.code).to eq('401') }
    end
  end
end
