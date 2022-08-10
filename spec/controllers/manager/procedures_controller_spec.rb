describe Manager::ProceduresController, type: :controller do
  let(:super_admin) { create :super_admin }
  let(:administrateur) { create(:administrateur, email: super_admin.email) }
  let(:autre_administrateur) { create(:administrateur) }
  before { sign_in super_admin }

  describe '#whitelist' do
    let(:procedure) { create(:procedure) }

    before do
      post :whitelist, params: { id: procedure.id }
      procedure.reload
    end

    it { expect(procedure.whitelisted?).to be_truthy }
  end

  describe '#show' do
    render_views

    let(:procedure) { create(:procedure, :published, :with_repetition) }

    before do
      get :show, params: { id: procedure.id }
    end

    it { expect(response.body).to include('sub type de champ') }
  end

  describe '#discard' do
    let(:dossier) { create(:dossier, :accepte) }
    let(:procedure) { dossier.procedure }

    before do
      post :discard, params: { id: procedure.id }
      procedure.reload
      dossier.reload
    end

    it { expect(procedure.discarded?).to be_truthy }
    it { expect(dossier.hidden_by_administration?).to be_truthy }
  end

  describe '#restore' do
    let(:dossier) { create(:dossier, :accepte, :with_individual) }
    let(:procedure) { dossier.procedure }

    before do
      procedure.discard_and_keep_track!(super_admin)

      post :restore, params: { id: procedure.id }
      procedure.reload
    end

    it { expect(procedure.kept?).to be_truthy }
    it { expect(dossier.hidden_by_administration?).to be_falsey }
  end

  describe '#index' do
    render_views

    context 'sort by dossiers' do
      let!(:dossier) { create(:dossier) }

      before do
        get :index, params: { procedure: { direction: :asc, order: :dossiers } }
      end

      it { expect(response.body).to include('1 dossier') }
    end
  end

  describe '#delete_administrateur' do
    let(:procedure) { create(:procedure, :with_service, administrateurs: [administrateur, autre_administrateur]) }

    before do
      put :delete_administrateur, params: { id: procedure.id }
    end

    it { expect(procedure.administrateurs).to eq([autre_administrateur]) }
  end
end
