describe ChampSerializer do
  describe '#attributes' do
    subject { ChampSerializer.new(serializable_object).serializable_hash }
    let(:serializable_object) { champ }

    context 'when type champ is piece justificative' do
      include Rails.application.routes.url_helpers

      let(:champ) { create(:champ_piece_justificative) }

      before { champ.piece_justificative_file.attach({ filename: __FILE__, io: File.open(__FILE__) }) }
      after { champ.piece_justificative_file.purge }

      it { is_expected.to include(value: champ.value) }
    end

    context 'when type champ is not piece justificative' do
      let(:champ) { create(:champ, value: "blah") }

      it { is_expected.to include(value: "blah") }
    end

    context 'when type champ is carte' do
      let(:champ) { create(:champ_carte, value: value, geo_areas: [geo_area].compact) }
      let(:value) { nil }
      let(:geo_area) { create(:geo_area, geometry: parsed_geo_json) }
      let(:parsed_geo_json) { JSON.parse(geo_json) }
      let(:geo_json) { GeojsonService.to_json_polygon_for_selection_utilisateur(coordinates) }
      let(:coordinates) { [[{ "lat" => 48.87442541960633, "lng" => 2.3859214782714844 }, { "lat" => 48.87273183590832, "lng" => 2.3850631713867183 }, { "lat" => 48.87081237174292, "lng" => 2.3809432983398438 }, { "lat" => 48.8712640169951, "lng" => 2.377510070800781 }, { "lat" => 48.87510283703279, "lng" => 2.3778533935546875 }, { "lat" => 48.87544154230615, "lng" => 2.382831573486328 }, { "lat" => 48.87442541960633, "lng" => 2.3859214782714844 }]] }

      let(:serialized_champ) {
        {
          type_de_champ: serialized_type_de_champ,
          value: serialized_value
        }
      }
      let(:serialized_type_de_champ) {
        {
          description: serialized_description,
          id: serialized_id,
          libelle: serialized_libelle,
          order_place: serialized_order_place,
          type_champ: serialized_type_champ
        }
      }
      let(:serialized_id) { -1 }
      let(:serialized_description) { "" }
      let(:serialized_order_place) { -1 }
      let(:serialized_value) { parsed_geo_json }

      context 'and geo_area is selection_utilisateur' do
        context 'value is empty' do
          context 'when value is nil' do
            let(:value) { nil }

            it { expect(champ.user_geo_area).to be_nil }
          end

          context 'when value is empty array' do
            let(:value) { '[]' }

            it { expect(champ.user_geo_area).to be_nil }
          end

          context 'when value is blank' do
            let(:value) { '' }

            it { expect(champ.user_geo_area).to be_nil }
          end
        end

        context 'old_api' do
          let(:serialized_libelle) { "user geometry" }
          let(:serialized_type_champ) { "user_geometry" }

          let(:serializable_object) { champ.user_geo_area }

          context 'when value is coordinates' do
            let(:value) { coordinates.to_json }

            it { expect(subject).to eq(serialized_champ) }
          end

          context 'when value is geojson' do
            let(:value) { geo_json }

            it { expect(subject).to eq(serialized_champ) }
          end
        end

        context 'new_api' do
          let(:geo_area) { nil }
          let(:serialized_champ) {
            {
              type_de_champ: serialized_type_de_champ,
              geo_areas: [],
              value: serialized_value
            }
          }
          let(:serialized_id) { champ.type_de_champ.stable_id }
          let(:serialized_description) { champ.description }
          let(:serialized_order_place) { champ.order_place }
          let(:serialized_libelle) { champ.libelle }
          let(:serialized_type_champ) { champ.type_champ }
          let(:serialized_value) { geo_json }

          context 'when value is coordinates' do
            let(:value) { coordinates.to_json }

            it { expect(subject).to eq(serialized_champ) }
          end

          context 'when value is geojson' do
            let(:value) { geo_json }

            it { expect(subject).to eq(serialized_champ) }
          end

          context 'when value is nil' do
            let(:value) { nil }
            let(:serialized_value) { nil }

            it { expect(subject).to eq(serialized_champ) }
          end

          context 'when value is empty array' do
            let(:value) { '[]' }
            let(:serialized_value) { nil }

            it { expect(subject).to eq(serialized_champ) }
          end

          context 'when value is blank' do
            let(:value) { '' }
            let(:serialized_value) { nil }

            it { expect(subject).to eq(serialized_champ) }
          end
        end
      end

      context 'and geo_area is cadastre' do
        context 'new_api' do
          it {
            expect(subject[:geo_areas].first).to include(
              source: GeoArea.sources.fetch(:cadastre),
              geometry: parsed_geo_json,
              numero: '42',
              feuille: 'A11'
            )
            expect(subject[:geo_areas].first.key?(:nom)).to be_falsey
          }
        end

        context 'old_api' do
          let(:serializable_object) { champ.geo_areas.first }
          let(:serialized_libelle) { "cadastre" }
          let(:serialized_type_champ) { "cadastre" }

          it { expect(subject).to eq(serialized_champ) }
        end
      end

      context 'and geo_area is quartier_prioritaire' do
        let(:geo_area) { create(:geo_area, :quartier_prioritaire, geometry: parsed_geo_json) }

        context 'new_api' do
          it {
            expect(subject[:geo_areas].first).to include(
              source: GeoArea.sources.fetch(:quartier_prioritaire),
              geometry: parsed_geo_json,
              nom: 'XYZ',
              commune: 'Paris'
            )
            expect(subject[:geo_areas].first.key?(:numero)).to be_falsey
          }
        end

        context 'old_api' do
          let(:serializable_object) { champ.geo_areas.first }
          let(:serialized_libelle) { "quartier prioritaire" }
          let(:serialized_type_champ) { "quartier_prioritaire" }

          it { expect(subject).to eq(serialized_champ) }
        end
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

    context 'when type champ yes_no' do
      context 'true' do
        let(:champ) { create(:champ_yes_no, value: 'true') }

        it { is_expected.to include(value: 'true') }
      end

      context 'false' do
        let(:champ) { create(:champ_yes_no, value: 'false') }

        it { is_expected.to include(value: 'false') }
      end

      context 'nil' do
        let(:champ) { create(:champ_yes_no, value: nil) }

        it { is_expected.to include(value: nil) }
      end
    end

    context 'when type champ checkbox' do
      context 'on' do
        let(:champ) { create(:champ_checkbox, value: 'on') }

        it { is_expected.to include(value: 'on') }
      end

      context 'off' do
        let(:champ) { create(:champ_checkbox, value: 'off') }

        it { is_expected.to include(value: 'off') }
      end

      context 'nil' do
        let(:champ) { create(:champ_checkbox, value: nil) }

        it { is_expected.to include(value: nil) }
      end
    end

    context 'when type champ engagement' do
      context 'on' do
        let(:champ) { create(:champ_engagement, value: 'on') }

        it { is_expected.to include(value: 'on') }
      end

      context 'off' do
        let(:champ) { create(:champ_engagement, value: 'off') }

        it { is_expected.to include(value: 'off') }
      end

      context 'nil' do
        let(:champ) { create(:champ_engagement, value: nil) }

        it { is_expected.to include(value: nil) }
      end
    end
  end
end
