describe ChampSerializer do
  describe '#attributes' do
    subject { ChampSerializer.new(champ).serializable_hash }

    context 'when type champ is piece justificative' do
      include Rails.application.routes.url_helpers

      let(:champ) { create(:champ_piece_justificative) }

      before { champ.piece_justificative_file.attach({ filename: __FILE__, io: File.open(__FILE__) }) }
      after { champ.piece_justificative_file.purge }

      it { is_expected.to include(value: url_for(champ.piece_justificative_file)) }
    end

    context 'when type champ is not piece justificative' do
      let(:champ) { create(:champ, value: "blah") }

      it { is_expected.to include(value: "blah") }
    end

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

    context 'when type champ is siret' do
      let(:etablissement) { create(:etablissement) }
      let(:champ) { create(:type_de_champ_siret).champ.create(etablissement: etablissement, value: etablissement.siret) }

      it {
        is_expected.to include(value: etablissement.siret)
        expect(subject[:etablissement]).to include(siret: etablissement.siret)
        expect(subject[:entreprise]).to include(capital_social: etablissement.entreprise_capital_social)
      }
    end
  end
end
