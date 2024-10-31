# frozen_string_literal: true

describe Columns::ChampColumn do
  describe '#value' do
    context 'when champ columns' do
      let(:procedure) { create(:procedure, :with_all_champs_mandatory) }
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
