require 'spec_helper'

describe NewGestionnaire::AvisController, type: :controller do
  render_views

  let(:claimant) { create(:gestionnaire) }
  let(:gestionnaire) { create(:gestionnaire) }
  let(:procedure) { create(:procedure, :published, gestionnaires: [gestionnaire]) }
  let(:dossier) { create(:dossier, :en_construction, procedure: procedure) }
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
    let(:file) { nil }
    let(:scan_result) { true }

    subject { post :create_commentaire, { id: avis_without_answer.id, commentaire: { body: 'commentaire body', file: file } } }

    before do
      allow(ClamavService).to receive(:safe_file?).and_return(scan_result)
    end

    it do
      subject

      expect(response).to redirect_to(messagerie_avis_path(avis_without_answer))
      expect(dossier.commentaires.map(&:body)).to match(['commentaire body'])
    end

    context "with a file" do
      let(:file) { Rack::Test::UploadedFile.new("./spec/support/files/piece_justificative_0.pdf", 'application/pdf') }

      it do
        subject
        expect(Commentaire.last.file.path).to include("piece_justificative_0.pdf")
      end

      it { expect { subject }.to change(Commentaire, :count).by(1) }

      context "and a virus" do
        let(:scan_result) { false }

        it { expect { subject }.not_to change(Commentaire, :count) }
      end
    end
  end

  describe '#create_avis' do
    let!(:previous_avis) { Avis.create(dossier: dossier, claimant: claimant, gestionnaire: gestionnaire, confidentiel: previous_avis_confidentiel) }
    let(:email) { 'a@b.com' }
    let(:intro) { 'introduction' }
    let(:created_avis) { Avis.last }

    before do
      post :create_avis, { id: previous_avis.id, avis: { email: email, introduction: intro, confidentiel: asked_confidentiel } }
    end

    context 'when the previous avis is public' do
      let(:previous_avis_confidentiel) { false }

      context 'when the user asked for a public avis' do
        let(:asked_confidentiel) { false }

        it { expect(created_avis.confidentiel).to be(false) }
        it { expect(created_avis.email).to eq(email) }
        it { expect(created_avis.introduction).to eq(intro) }
        it { expect(created_avis.dossier).to eq(previous_avis.dossier) }
        it { expect(created_avis.claimant).to eq(gestionnaire) }
        it { expect(response).to redirect_to(instruction_avis_path(previous_avis)) }
      end

      context 'when the user asked for a confidentiel avis' do
        let(:asked_confidentiel) { true }

        it { expect(created_avis.confidentiel).to be(true) }
      end
    end

    context 'when the preivous avis is confidentiel' do
      let(:previous_avis_confidentiel) { true }

      context 'when the user asked for a public avis' do
        let(:asked_confidentiel) { false }

        it { expect(created_avis.confidentiel).to be(true) }
      end
    end
  end
end
