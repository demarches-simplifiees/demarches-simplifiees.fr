describe Manager::DossiersController, type: :controller do
  describe '#discard' do
    let(:administration) { create :administration }
    let(:dossier) { create(:dossier) }

    before do
      sign_in administration
      post :discard, params: { id: dossier.id }
      dossier.reload
    end

    it { expect(dossier.discarded?).to be_truthy }
  end

  describe '#repasser_en_instruction' do
    let(:administration) { create :administration }
    let(:dossier) { create(:dossier, :accepte) }

    before do
      sign_in administration
      post :repasser_en_instruction, params: { id: dossier.id }
      dossier.reload
    end

    it { expect(dossier.en_instruction?).to be_truthy }
  end
end
