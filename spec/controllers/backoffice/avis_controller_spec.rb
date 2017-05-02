require 'spec_helper'

describe Backoffice::AvisController, type: :controller do

  describe '#POST create' do
    let(:gestionnaire){ create(:gestionnaire) }
    let!(:dossier){ create(:dossier, state: 'received') }
    let!(:assign_to){ create(:assign_to, gestionnaire: gestionnaire, procedure: dossier.procedure )}

    subject { post :create, params: { dossier_id: dossier.id, avis: { email: gestionnaire.email, introduction: "Bonjour, regardez ce joli dossier." } } }

    context 'when gestionnaire is not authenticated' do
      it { is_expected.to redirect_to new_user_session_path }
      it { expect{ subject }.to_not change(Avis, :count) }
    end

    context 'when gestionnaire is authenticated' do
      before do
        sign_in gestionnaire
      end

      context 'When gestionnaire is known' do
        it { is_expected.to redirect_to backoffice_dossier_path(dossier.id) }
        it { expect{ subject }.to change(Avis, :count).by(1) }
        it do
          subject
          expect(gestionnaire.avis.last).to_not eq(nil)
          expect(gestionnaire.avis.last.email).to eq(nil)
          expect(gestionnaire.avis.last.dossier_id).to eq(dossier.id)
        end
      end
    end
  end

end
