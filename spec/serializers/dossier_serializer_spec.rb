describe DossierSerializer do
  describe '#attributes' do
    subject { DossierSerializer.new(dossier).serializable_hash }

    context 'when the dossier is en_construction' do
      let(:dossier) { create(:dossier, :en_construction) }

      it { is_expected.to include(initiated_at: dossier.en_construction_at) }
      it { is_expected.to include(state: 'initiated') }
    end
  end
end
