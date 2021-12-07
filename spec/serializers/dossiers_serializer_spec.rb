describe DossiersSerializer do
  describe '#attributes' do
    subject { DossiersSerializer.new(dossier).serializable_hash }

    context 'when the dossier is en_construction' do
      let(:dossier) { create(:dossier, :en_construction) }

      it { is_expected.to include(initiated_at: dossier.depose_at) }
      it { is_expected.to include(state: 'initiated') }
    end
  end
end
