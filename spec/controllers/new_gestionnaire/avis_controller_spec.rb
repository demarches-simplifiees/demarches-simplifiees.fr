require 'spec_helper'

describe NewGestionnaire::AvisController, type: :controller do
  render_views

  let(:claimant) { create(:gestionnaire) }
  let(:gestionnaire) { create(:gestionnaire) }
  let(:procedure) { create(:procedure, :published, gestionnaires: [gestionnaire]) }
  let(:dossier) { create(:dossier, :replied, procedure: procedure) }
  let!(:avis_without_answer) { Avis.create(dossier: dossier, claimant: claimant, gestionnaire: gestionnaire) }
  let!(:avis_with_answer) { Avis.create(dossier: dossier, claimant: claimant, gestionnaire: gestionnaire, answer: 'yop') }

  before { sign_in(gestionnaire) }

  describe '#index' do
    before { get :index }

    it { expect(response).to have_http_status(:success) }
    it { expect(assigns(:avis_a_donner)).to match([avis_without_answer]) }
    it { expect(assigns(:avis_donnes)).to match([avis_with_answer]) }
    it { expect(assigns(:statut)).to eq('a-donner') }

    context 'with a statut equal to donnes' do
      before { get :index, statut: 'donnes' }

      it { expect(assigns(:statut)).to eq('donnes') }
    end
  end

  describe '#show' do
    before { get :show, { id: avis_without_answer.id } }

    it { expect(response).to have_http_status(:success) }
    it { expect(assigns(:avis)).to eq(avis_without_answer) }
    it { expect(assigns(:dossier)).to eq(dossier) }
  end

  describe '#instruction' do
    before { get :instruction, { id: avis_without_answer.id } }

    it { expect(response).to have_http_status(:success) }
    it { expect(assigns(:avis)).to eq(avis_without_answer) }
    it { expect(assigns(:dossier)).to eq(dossier) }
  end

  describe '#messagerie' do
    before { get :messagerie, { id: avis_without_answer.id } }

    it { expect(response).to have_http_status(:success) }
    it { expect(assigns(:avis)).to eq(avis_without_answer) }
    it { expect(assigns(:dossier)).to eq(dossier) }
  end

  describe '#update' do
    before do
      patch :update, { id: avis_without_answer.id, avis: { answer: 'answer' } }
      avis_without_answer.reload
    end

    it { expect(response).to redirect_to(instruction_avis_path(avis_without_answer)) }
    it { expect(avis_without_answer.answer).to eq('answer') }
    it { expect(flash.notice).to eq('Votre réponse est enregistrée.') }
  end

  describe '#create_commentaire' do
    before do
      post :create_commentaire, { id: avis_without_answer.id, commentaire: { body: 'commentaire body' } }
    end

    it { expect(response).to redirect_to(messagerie_avis_path(avis_without_answer)) }
    it { expect(dossier.commentaires.map(&:body)).to match(['commentaire body']) }
  end
end
