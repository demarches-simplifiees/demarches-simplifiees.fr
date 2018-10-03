require 'spec_helper'

describe Champs::DossierLinkController, type: :controller do
  let(:user) { create(:user) }
  let(:procedure) { create(:procedure, :published) }

  describe '#show' do
    let(:dossier) { create(:dossier, user: user, procedure: procedure) }

    context 'when user is connected' do
      render_views
      before { sign_in user }

      let(:params) do
        {
          dossier: {
            champs_attributes: {
              '1' => { value: dossier_id.to_s }
            }
          },
          position: '1'
        }
      end
      let(:dossier_id) { dossier.id }

      context 'when the dossier exist' do
        before {
          get :show, params: params, format: 'js'
        }

        it 'returns the procedure name' do
          expect(response.body).to include('Dossier en brouillon')
          expect(response.body).to include(procedure.libelle)
          expect(response.body).to include(procedure.organisation)
        end
      end

      context 'when the dossier does not exist' do
        let(:dossier_id) { '13' }
        before {
          get :show, params: params, format: 'js'
        }

        it { expect(response.body).to include('Ce dossier est inconnu') }
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
