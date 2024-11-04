# frozen_string_literal: true

describe Columns::ChampColumn do
  describe '#value' do
    let(:procedure) { create(:procedure, :with_all_champs_mandatory) }

    context 'without any cast' do
      let(:dossier) { create(:dossier, :with_populated_champs, procedure:) }
      let(:types_de_champ) { procedure.all_revisions_types_de_champ }

      it 'extracts values for columns and type de champ' do
        expect_type_de_champ_values('civilite', ["M."])
        expect_type_de_champ_values('email', ['yoda@beta.gouv.fr'])
        expect_type_de_champ_values('phone', ['0666666666'])
        expect_type_de_champ_values('address', ["2 rue des Démarches"])
        expect_type_de_champ_values('communes', ["Coye-la-Forêt"])
        expect_type_de_champ_values('departements', ['01'])
        expect_type_de_champ_values('regions', ['01'])
        expect_type_de_champ_values('pays', ['France'])
        expect_type_de_champ_values('epci', [nil])
        expect_type_de_champ_values('iban', [nil])
        expect_type_de_champ_values('siret', ["44011762001530", "postal_code", "city_name", "departement_code", "region_name"])
        expect_type_de_champ_values('text', ['text'])
        expect_type_de_champ_values('textarea', ['textarea'])
        expect_type_de_champ_values('number', ['42'])
        expect_type_de_champ_values('decimal_number', [42.1])
        expect_type_de_champ_values('integer_number', [42])
        expect_type_de_champ_values('date', [Time.zone.parse('2019-07-10').to_date])
        expect_type_de_champ_values('datetime', [Time.zone.parse("1962-09-15T15:35:00+01:00")])
        expect_type_de_champ_values('checkbox', [true])
        expect_type_de_champ_values('drop_down_list', ['val1'])
        expect_type_de_champ_values('multiple_drop_down_list', [["val1", "val2"]])
        expect_type_de_champ_values('linked_drop_down_list', [nil, "categorie 1", "choix 1"])
        expect_type_de_champ_values('yes_no', [true])
        expect_type_de_champ_values('annuaire_education', [nil])
        expect_type_de_champ_values('carte', [])
        expect_type_de_champ_values('piece_justificative', [])
        expect_type_de_champ_values('titre_identite', [true])
        expect_type_de_champ_values('cnaf', [nil])
        expect_type_de_champ_values('dgfip', [nil])
        expect_type_de_champ_values('pole_emploi', [nil])
        expect_type_de_champ_values('mesri', [nil])
        expect_type_de_champ_values('cojo', [nil])
        expect_type_de_champ_values('expression_reguliere', [nil])
      end
    end

    context 'with cast' do
      def column(label) = procedure.find_column(label:)

      context 'from a integer_number' do
        let(:champ) { double(last_write_type_champ: 'integer_number', value: '42') }

        it do
          expect(column('decimal_number').value(champ)).to eq(42.0)
          expect(column('text').value(champ)).to eq('42')
        end
      end

      context 'from a decimal_number' do
        let(:champ) { double(last_write_type_champ: 'decimal_number', value: '42.1') }

        it do
          expect(column('integer_number').value(champ)).to eq(42)
          expect(column('text').value(champ)).to eq('42.1')
        end
      end

      context 'from a date' do
        let(:champ) { double(last_write_type_champ: 'date', value:) }

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
        let(:champ) { double(last_write_type_champ: 'datetime', value:) }

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
        let(:champ) { double(last_write_type_champ: 'drop_down_list', value: 'val1') }

        it do
          expect(column('multiple_drop_down_list').value(champ)).to eq(['val1'])
          expect(column('text').value(champ)).to eq('val1')
        end
      end

      context 'from a multiple_drop_down_list' do
        let(:champ) { double(last_write_type_champ: 'multiple_drop_down_list', value: '["val1","val2"]') }

        it do
          expect(column('simple_drop_down_list').value(champ)).to eq('val1')
          expect(column('text').value(champ)).to eq('val1, val2')
        end
      end
    end
  end

  private

  def expect_type_de_champ_values(type, values)
    type_de_champ = types_de_champ.find { _1.type_champ == type }
    champ = dossier.send(:filled_champ, type_de_champ, nil)
    columns = type_de_champ.columns(procedure_id: procedure.id)
    expect(columns.map { _1.value(champ) }).to eq(values)
  end

  def retrieve_champ(type)
    type_de_champ = types_de_champ.find { _1.type_champ == type }
    dossier.send(:filled_champ, type_de_champ, nil)
  end
end
