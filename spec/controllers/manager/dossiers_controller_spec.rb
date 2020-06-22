describe Manager::DossiersController, type: :controller do
  let(:administration) { create :administration }
  let(:deleted_dossier) { DeletedDossier.find_by(dossier_id: dossier) }
  let(:operations) { dossier.dossier_operation_logs.map(&:operation).map(&:to_sym) }

  before { sign_in administration }

  describe '#discard' do
    let(:dossier) { create(:dossier, :en_construction) }

    before do
      post :discard, params: { id: dossier.id }
      dossier.reload
    end

    it { expect(dossier.discarded?).to be_truthy }
    it { expect(deleted_dossier).not_to be_nil }
    it { expect(deleted_dossier.reason).to eq("manager_request") }
    it { expect(operations).to eq([:supprimer]) }
  end

  describe '#restore' do
    let(:dossier) { create(:dossier, :en_construction) }

    before do
      dossier.discard_and_keep_track!(administration, :manager_request)

      post :restore, params: { id: dossier.id }
      dossier.reload
    end

    it { expect(dossier.kept?).to be_truthy }
    it { expect(deleted_dossier).to be_nil }
    it { expect(operations).to eq([:supprimer, :restaurer]) }
  end

  describe '#repasser_en_instruction' do
    let(:dossier) { create(:dossier, :accepte) }

    before do
      post :repasser_en_instruction, params: { id: dossier.id }
      dossier.reload
    end

    it { expect(dossier.en_instruction?).to be_truthy }
  end
end
