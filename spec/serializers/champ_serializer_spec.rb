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
      let(:coordinates) { [[{ "lat": 48.87442541960633, "lng": 2.3859214782714844 }, { "lat": 48.87273183590832, "lng": 2.3850631713867183 }, { "lat": 48.87081237174292, "lng": 2.3809432983398438 }, { "lat": 48.8712640169951, "lng": 2.377510070800781 }, { "lat": 48.87510283703279, "lng": 2.3778533935546875 }, { "lat": 48.87544154230615, "lng": 2.382831573486328 }, { "lat": 48.87442541960633, "lng": 2.3859214782714844 }]] }

      let(:champ_carte) { create(:champ_carte, value: coordinates.to_json, geo_areas: [geo_area]) }
      let(:champ) { champ_carte }

      context 'legacy champ user_geometry' do
        let(:champ) { champ_carte.user_geo_area }

        it {
          expect(subject).to include(
            type_de_champ: {
              descripton: "",
              id: -1,
              libelle: "user geometry",
              order_place: -1,
              type_champ: "user_geometry"
            },
            value: champ_carte.user_geometry
          )
        }
      end

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
