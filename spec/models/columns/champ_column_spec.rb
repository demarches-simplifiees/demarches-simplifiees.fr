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
        expect_type_de_champ_values('address', eq(["2 rue des Démarches", "38000", "grenoble", "38", "Auvergne-Rhones-Alpes"]))
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
        expect_type_de_champ_values('formatted', eq([nil]))
        expect_type_de_champ_values('rna', eq(["W173847273", "postal_code", "city_name", "department_code", "region_name", "LA PRÉVENTION ROUTIERE"]))
        expect_type_de_champ_values('rnf', eq(["075-FDD-00003-01", "postal_code", "city_name", "department_code", "region_name", "Fondation SFR"]))
      end
    end

    context 'with cast' do
      def column(label) = procedure.find_column(label:)

      context 'from a text' do
        let(:champ) { Champs::TextChamp.new(value: 'hello') }

        it do
          expect(column('formatted').value(champ)).to eq('hello')
          expect(column('textarea').value(champ)).to eq('hello')
        end
      end

      context 'from a formatted' do
        let(:champ) { Champs::FormattedChamp.new(value: 'hello') }

        it do
          expect(column('text').value(champ)).to eq('hello')
          expect(column('textarea').value(champ)).to eq('hello')
        end
      end

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

  describe '#filtered_ids' do
    subject { column.filtered_ids(dossiers, search_terms) }

    context "with a yes no champ not mandatory" do
      let(:procedure) { create(:procedure, types_de_champ_public: [{ type: :yes_no, mandatory: false, libelle: "oui/non" }]) }
      let(:dossier_with_yes) { create(:dossier, :en_instruction, procedure:) }
      let(:dossier_with_no) { create(:dossier, :en_instruction, procedure:) }
      let(:dossier_not_filled) { create(:dossier, :en_instruction, procedure:) }

      let(:column) { procedure.find_column(label: "oui/non") }
      let(:dossiers) { procedure.dossiers }

      before do
        dossier_with_yes.champs.first.update!(value: "true")
        dossier_with_no.champs.first.update!(value: "false")
        dossier_not_filled.champs.first.destroy!
      end

      context "when searching for a yes" do
        let(:search_terms) { ["true"] }

        it "returns the correct ids" do
          expect(subject).to eq([dossier_with_yes.id])
        end
      end

      context "when searching for a no" do
        let(:search_terms) { ["false"] }

        it "returns the correct ids" do
          expect(subject).to eq([dossier_with_no.id])
        end
      end

      context "when searching for a nil" do
        let(:search_terms) { [Column::NOT_FILLED_VALUE] }

        it "returns the correct ids" do
          expect(subject).to eq([dossier_not_filled.id])
        end
      end
    end

    context "with a checkbox champ not mandatory" do
      let(:procedure) { create(:procedure, types_de_champ_public: [{ type: :checkbox, mandatory: false, libelle: "checkbox" }]) }
      let(:dossier_with_checked) { create(:dossier, :en_instruction, procedure:) }
      let(:dossier_not_checked) { create(:dossier, :en_instruction, procedure:) }

      before do
        dossier_with_checked.champs.first.update!(value: "true")
        dossier_not_checked.champs.first.destroy!
      end

      let(:column) { procedure.find_column(label: "checkbox") }
      let(:dossiers) { procedure.dossiers }

      context "when searching for a checked" do
        let(:search_terms) { ["true"] }

        it "returns the correct ids" do
          expect(subject).to eq([dossier_with_checked.id])
        end
      end

      context "when searching for a not checked" do
        let(:search_terms) { ["false"] }

        it "returns the correct ids" do
          expect(subject).to eq([dossier_not_checked.id])
        end
      end
    end

    context "with a checkbox champ not mandatory" do
      let(:procedure) { create(:procedure, types_de_champ_public: [{ type: :checkbox, mandatory: false, libelle: "checkbox" }]) }
      let(:dossier_with_checked) { create(:dossier, :en_instruction, procedure:) }
      let(:dossier_not_checked) { create(:dossier, :en_instruction, procedure:) }

      before do
        dossier_with_checked.champs.first.update!(value: "true")
        dossier_not_checked.champs.first.destroy!
      end

      let(:column) { procedure.find_column(label: "checkbox") }
      let(:dossiers) { procedure.dossiers }

      context "when searching for a checked" do
        let(:search_terms) { ["true"] }

        it "returns the correct ids" do
          expect(subject).to eq([dossier_with_checked.id])
        end
      end

      context "when searching for a not checked" do
        let(:search_terms) { ["false"] }

        it "returns the correct ids" do
          expect(subject).to eq([dossier_not_checked.id])
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
