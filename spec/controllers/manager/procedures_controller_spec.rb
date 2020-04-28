describe Manager::ProceduresController, type: :controller do
  let(:administration) { create :administration }

  before { sign_in administration }

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

    let(:procedure) { create(:procedure, :with_repetition) }

    before do
      get :show, params: { id: procedure.id }
    end

    it { expect(response.body).to include('sub type de champ') }
  end

  describe '#discard' do
    let(:dossier) { create(:dossier, :en_construction) }
    let(:procedure) { dossier.procedure }
    let(:deleted_dossier) { DeletedDossier.find_by(dossier_id: dossier.id) }
    let(:operations) { dossier.dossier_operation_logs.map(&:operation).map(&:to_sym) }

    before do
      post :discard, params: { id: procedure.id }
      procedure.reload
      dossier.reload
    end

    it { expect(procedure.discarded?).to be_truthy }
    it { expect(dossier.discarded?).to be_truthy }
    it { expect(deleted_dossier).not_to be_nil }
    it { expect(deleted_dossier.reason).to eq("procedure_removed") }
    it { expect(operations).to eq([:supprimer]) }
  end

  describe '#restore' do
    let(:dossier) { create(:dossier, :en_construction) }
    let(:procedure) { dossier.procedure }
    let(:deleted_dossier) { DeletedDossier.find_by(dossier_id: dossier.id) }
    let(:operations) { dossier.dossier_operation_logs.map(&:operation).map(&:to_sym) }

    before do
      procedure.discard_and_keep_track!(administration)

      post :restore, params: { id: procedure.id }
      procedure.reload
    end

    it { expect(procedure.kept?).to be_truthy }
    it { expect(dossier.kept?).to be_truthy }
    it { expect(deleted_dossier).to be_nil }
    it { expect(operations).to eq([:supprimer, :restaurer]) }
  end

  describe '#index' do
    render_views

    context 'sort by dossiers' do
      let!(:dossier) { create(:dossier) }

      before do
        get :index, params: { procedure: { direction: 'asc', order: 'dossiers' } }
      end

      it { expect(response.body).to include('1 dossier') }
    end
  end
end
