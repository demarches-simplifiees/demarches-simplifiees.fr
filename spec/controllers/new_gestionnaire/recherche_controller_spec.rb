require 'spec_helper'

describe NewGestionnaire::RechercheController, type: :controller do
  let(:dossier) { create(:dossier, :en_construction) }
  let(:dossier2) { create(:dossier, :en_construction, procedure: dossier.procedure) }
  let(:gestionnaire) { create(:gestionnaire) }

  before { gestionnaire.procedures << dossier2.procedure }

  describe 'GET #index' do
    before { sign_in gestionnaire }

    subject { get :index, params: { q: query } }

    describe 'by id' do
      context 'when gestionnaire own the dossier' do
        let(:query) { dossier.id }

        it { is_expected.to have_http_status(200) }

        it 'returns the expected dossier' do
          subject
          expect(assigns(:dossiers).count).to eq(1)
          expect(assigns(:dossiers).first.id).to eq(dossier.id)
        end
      end

      context 'when gestionnaire do not own the dossier' do
        let(:dossier3) { create(:dossier, :en_construction) }
        let(:query) { dossier3.id }

        it { is_expected.to have_http_status(200) }

        it 'does not return the dossier' do
          subject
          expect(assigns(:dossiers).count).to eq(0)
        end
      end
    end
  end
end
