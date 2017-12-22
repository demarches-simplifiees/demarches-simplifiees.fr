require 'spec_helper'

describe Backoffice::AvisController, type: :controller do
  describe '#POST create' do
    let(:claimant){ create(:gestionnaire) }
    let(:gestionnaire){ create(:gestionnaire) }
    let!(:dossier) do
      dossier = create(:dossier, state: 'en_instruction')
      claimant.procedures << [dossier.procedure]
      dossier
    end

    subject do
      post :create, params: { dossier_id: dossier.id, avis: { email: gestionnaire.email, introduction: "Bonjour, regardez ce joli dossier." } }
    end

    context 'when gestionnaire is not authenticated' do
      before { subject }

      it { expect(response).to redirect_to new_user_session_path }
      it { expect(Avis.count).to eq(0) }
    end

    context 'when gestionnaire is authenticated' do
      let(:created_avis) { Avis.last }

      before do
        sign_in claimant
        subject
      end

      it { expect(response).to redirect_to backoffice_dossier_path(dossier.id) }
      it { expect(Avis.count).to eq(1) }
      it { expect(created_avis.dossier_id).to eq(dossier.id) }
      it { expect(created_avis.gestionnaire).to eq(gestionnaire) }
      it { expect(created_avis.claimant).to eq(claimant) }
      it { expect(created_avis.confidentiel).to be(true) }
    end
  end

  describe '#POST update' do
    let(:gestionnaire){ create(:gestionnaire) }
    let(:dossier){ create(:dossier, state: 'en_instruction') }
    let(:avis){ create(:avis, dossier: dossier, gestionnaire: gestionnaire )}

    subject { post :update, params: { dossier_id: dossier.id, id: avis.id, avis: { answer: "Ok ce dossier est valide." } } }

    before :each do
      notification = double('notification', notify: true)
      allow(NotificationService).to receive(:new).and_return(notification)
    end

    context 'when gestionnaire is not authenticated' do
      it { is_expected.to redirect_to new_user_session_path }
      it { expect(avis.answer).to be_nil }
    end

    context 'when gestionnaire is authenticated' do
      before do
        sign_in gestionnaire
      end

      context 'and is invited on dossier' do
        it { is_expected.to redirect_to backoffice_dossier_path(dossier.id) }
        it do
          subject
          expect(avis.reload.answer).to eq("Ok ce dossier est valide.")
          expect(NotificationService).to have_received(:new).at_least(:once)
        end
      end

      context 'but is not invited on dossier' do
        let(:gestionnaire2) { create(:gestionnaire) }
        let(:avis){ create(:avis, dossier: dossier, gestionnaire: gestionnaire2 )}

        it { expect{ subject }.to raise_error(ActiveRecord::RecordNotFound) }
      end
    end
  end
end
