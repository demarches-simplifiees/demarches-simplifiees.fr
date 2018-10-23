describe Champs::CarteChampSerializer do
  describe '#attributes' do
    subject { Champs::CarteChampSerializer.new(champ).serializable_hash }

    context 'when type champ is carte' do
      let(:geo_area) { create(:geo_area) }
      let(:champ) { create(:type_de_champ_carte).champ.create(geo_areas: [geo_area]) }

      context 'and geo_area is cadastre' do
        it {
          expect(subject[:geo_areas].first).to include(
            source: GeoArea.sources.fetch(:cadastre),
            numero: '42',
            feuille: 'A11'
          )
          expect(subject[:geo_areas].first.key?(:nom)).to be_falsey
        }
      end

      context 'and geo_area is quartier_prioritaire' do
        let(:geo_area) { create(:geo_area, :quartier_prioritaire) }

        it {
          expect(subject[:geo_areas].first).to include(
            source: GeoArea.sources.fetch(:quartier_prioritaire),
            nom: 'XYZ',
            commune: 'Paris'
          )
          expect(subject[:geo_areas].first.key?(:numero)).to be_falsey
        }
      end
    end
  end
end
