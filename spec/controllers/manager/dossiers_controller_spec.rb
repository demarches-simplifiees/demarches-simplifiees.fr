describe Manager::DossiersController, type: :controller do
  describe '#hide' do
    let(:administration) { create :administration }
    let!(:dossier) { create(:dossier) }

    before do
      sign_in administration
      post :hide, params: { id: dossier.id }
      dossier.reload
    end

    it { expect(dossier.hidden_at).not_to be_nil }
  end
end
