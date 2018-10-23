describe Champs::CarteChampSerializer do
  describe '#attributes' do
    subject { Champs::CarteChampSerializer.new(champ).serializable_hash }

    context 'when type champ is carte' do
      let(:geo_area) { create(:geo_area) }
      let(:champ) { create(:type_de_champ_carte).champ.create(geo_areas: [geo_area]) }

      it {
        expect(subject[:geo_areas].first).to include(
          source: GeoArea.sources.fetch(:cadastre),
          numero: '42',
          feuille: 'A11'
        )
      }
    end
  end
end
