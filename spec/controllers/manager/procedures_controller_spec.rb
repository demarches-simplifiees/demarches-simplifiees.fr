describe Manager::ProceduresController, type: :controller do
  describe '#whitelist' do
    let(:administration) { create :administration }
    let(:procedure) { create(:procedure) }

    before do
      sign_in administration
      post :whitelist, params: { id: procedure.id }
      procedure.reload
    end

    it { expect(procedure.whitelisted_at).not_to be_nil }
  end

  describe '#show' do
    render_views

    let(:administration) { create(:administration) }
    let(:procedure) { create(:procedure, :with_repetition) }

    before do
      sign_in(administration)
      get :show, params: { id: procedure.id }
    end

    it { expect(response.body).to include('sub type de champ') }
  end

  describe '#discard' do
    let(:administration) { create :administration }
    let(:procedure) { create(:procedure) }

    before do
      sign_in administration
      post :discard, params: { id: procedure.id }
      procedure.reload
    end

    it { expect(procedure.discarded?).to be_truthy }
  end

  describe '#index' do
    render_views

    let(:administration) { create(:administration) }
    let!(:dossier) { create(:dossier) }

    context 'sort by dossiers' do
      before do
        sign_in(administration)
        get :index, params: { procedure: { direction: 'asc', order: 'dossiers' } }
      end

      it { expect(response.body).to include('1 dossier') }
    end
  end
end
