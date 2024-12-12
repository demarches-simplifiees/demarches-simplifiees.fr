# frozen_string_literal: true

describe Columns::ChampColumn do
  describe '#value' do
    let(:procedure) { create(:procedure, :with_all_champs_mandatory) }

    context 'without any cast' do
      let(:dossier) { create(:dossier, :with_populated_champs, procedure:) }
      let(:types_de_champ) { procedure.all_revisions_types_de_champ }

      it 'extracts values for columns and type de champ' do
        expect_type_de_champ_values('civilite', eq(["M."]))
        expect_type_de_champ_values('email', eq(['yoda@beta.gouv.fr']))
        expect_type_de_champ_values('phone', eq(['0666666666']))
        expect_type_de_champ_values('address', eq(["2 rue des Démarches"]))
        expect_type_de_champ_values('communes', eq(["Coye-la-Forêt", "60580", "60"]))
        expect_type_de_champ_values('departements', eq(['01']))
        expect_type_de_champ_values('regions', eq(['01']))
        expect_type_de_champ_values('pays', eq(['France']))
        expect_type_de_champ_values('epci', eq([nil]))
        expect_type_de_champ_values('iban', eq([nil]))
        expect_type_de_champ_values('siret', match_array(
          [
            "44011762001530",
            "SA à conseil d'administration (s.a.i.)",
            "440117620",
            "GRTGAZ",
            "GRTGAZ",
            "1990-04-24",
            "Transports par conduites",
            "92270",
            "Bois-Colombes",
            "92",
            "Île-de-France"
          ]
        ))
        expect_type_de_champ_values('text', eq(['text']))
        expect_type_de_champ_values('textarea', eq(['textarea']))
        expect_type_de_champ_values('number', eq(['42']))
        expect_type_de_champ_values('decimal_number', eq([42.1]))
        expect_type_de_champ_values('integer_number', eq([42]))
        expect_type_de_champ_values('date', eq([Time.zone.parse('2019-07-10').to_date]))
        expect_type_de_champ_values('datetime', eq([Time.zone.parse("1962-09-15T15:35:00+01:00")]))
        expect_type_de_champ_values('checkbox', eq([true]))
        expect_type_de_champ_values('drop_down_list', eq(['val1']))
        expect_type_de_champ_values('multiple_drop_down_list', eq([["val1", "val2"]]))
        expect_type_de_champ_values('linked_drop_down_list', eq(["primary / secondary", "primary", "secondary"]))
        expect_type_de_champ_values('yes_no', eq([true]))
        expect_type_de_champ_values('annuaire_education', eq([nil]))
        expect_type_de_champ_values('piece_justificative', be_an_instance_of(Array))
        expect_type_de_champ_values('titre_identite', be_an_instance_of(Array))
        expect_type_de_champ_values('cnaf', eq([nil]))
        expect_type_de_champ_values('dgfip', eq([nil]))
        expect_type_de_champ_values('pole_emploi', eq([nil]))
        expect_type_de_champ_values('mesri', eq([nil]))
        expect_type_de_champ_values('cojo', eq([nil]))
        expect_type_de_champ_values('expression_reguliere', eq([nil]))
        expect_type_de_champ_values('rna', eq(["W173847273", "postal_code", "city_name", "departement_code", "region_name", "LA PRÉVENTION ROUTIERE"]))
        expect_type_de_champ_values('rnf', eq(["075-FDD-00003-01", "postal_code", "city_name", "departement_code", "region_name", "Fondation SFR"]))
      end
    end

    context 'with cast' do
      def column(label) = procedure.find_column(label:)

      context 'from a integer_number' do
        let(:champ) { Champs::IntegerNumberChamp.new(value: '42') }

        it do
          expect(column('decimal_number').value(champ)).to eq(42.0)
          expect(column('text').value(champ)).to eq('42')
        end
      end

      context 'from a decimal_number' do
        let(:champ) { Champs::DecimalNumberChamp.new(value: '42.1') }

        it do
          expect(column('integer_number').value(champ)).to eq(42)
          expect(column('text').value(champ)).to eq('42.1')
        end
      end

      context 'from a date' do
        let(:champ) { Champs::DateChamp.new(value:) }

        describe 'when the value is valid' do
          let(:value) { '2019-07-10' }

          it { expect(column('datetime').value(champ)).to eq(Time.zone.parse('2019-07-10')) }
        end

        describe 'when the value is invalid' do
          let(:value) { 'invalid' }

          it { expect(column('datetime').value(champ)).to be_nil }
        end
      end

      context 'from a datetime' do
        let(:champ) { Champs::DatetimeChamp.new(value:) }

        describe 'when the value is valid' do
          let(:value) { '1962-09-15T15:35:00+01:00' }

          it { expect(column('date').value(champ)).to eq('1962-09-15'.to_date) }
        end

        describe 'when the value is invalid' do
          let(:value) { 'invalid' }

          it { expect(column('date').value(champ)).to be_nil }
        end
      end

      context 'from a drop_down_list' do
        let(:champ) { Champs::DropDownListChamp.new(value:) }
        let(:value) { 'val1' }

        it do
          expect(column('multiple_drop_down_list').value(champ)).to eq(['val1'])
          expect(column('text').value(champ)).to eq('val1')
        end
      end

      context 'from a multiple_drop_down_list' do
        let(:champ) { Champs::MultipleDropDownListChamp.new(value:) }
        let(:value) { '["val1","val2"]' }

        it do
          expect(column('simple_drop_down_list').value(champ)).to eq('val1')
          expect(column('text').value(champ)).to eq('val1, val2')
        end
      end
    end
  end

  private

  def expect_type_de_champ_values(type, assertion)
    type_de_champ = types_de_champ.find { _1.type_champ == type }
    champ = dossier.send(:filled_champ, type_de_champ)
    columns = type_de_champ.columns(procedure:)
    expect(columns.map { _1.value(champ) }).to assertion
  end

  def retrieve_champ(type)
    type_de_champ = types_de_champ.find { _1.type_champ == type }
    dossier.send(:filled_champ, type_de_champ)
  end
end
