# frozen_string_literal: true

describe Column do
  describe 'get_value' do
    let(:procedure) { create(:procedure, :with_all_champs_mandatory) }
    let(:dossier) { create(:dossier, :with_populated_champs, procedure:) }

    context 'when params is a dossier' do
      let(:columns) do
        procedure.all_usager_columns_for_export +
        procedure.all_dossier_columns_for_export
      end
      it 'does not raise error' do
        expect { columns.map { _1.get_value(dossier) } }.not_to raise_error
      end
    end

    context 'when params is a champ' do
      let(:groupe_instructeur) { create(:groupe_instructeur, procedure:) }
      let(:export_template) { create(:export_template, groupe_instructeur:) }
      let(:types_de_champ) { procedure.all_revisions_types_de_champ }

      def expect_type_de_champ_values(type, values)
        type_de_champ = types_de_champ.find { _1.type_champ == type }
        champ = dossier.send(:filled_champ, type_de_champ, nil)
        columns = export_template.columns_for_stable_id(type_de_champ.stable_id)
        expect(columns.map { type_de_champ.champ_value_for_export(champ, _1.column) }).to eq(values)
      end

      def retrieve_champ(type)
        type_de_champ = types_de_champ.find { _1.type_champ == type }
        dossier.send(:filled_champ, type_de_champ, nil)
      end

      before do
        export_template.exported_columns =
          types_de_champ.flat_map { _1.columns(procedure_id: procedure.id) }
            .map { ExportedColumn.new(libelle: _1.label, column: _1) }
      end

      it 'extracts values for columns and type de champ' do
        expect_type_de_champ_values('engagement_juridique', ['EJ'])
        expect_type_de_champ_values('repetition', [])
        expect_type_de_champ_values('dossier_link', [retrieve_champ('dossier_link').value])
        expect_type_de_champ_values('civilite', ["M."])
        expect_type_de_champ_values('email', ['yoda@beta.gouv.fr'])
        expect_type_de_champ_values('phone', ['0666666666'])
        expect_type_de_champ_values('address', ["2 rue des Démarches"])
        expect_type_de_champ_values('communes', ["Coye-la-Forêt (60580)", "60172", "60"])
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
        expect_type_de_champ_values('date', ['2019-07-10'])
        expect_type_de_champ_values('datetime', ["1962-09-15T15:35:00+01:00"])
        expect_type_de_champ_values('checkbox', ['on'])
        expect_type_de_champ_values('drop_down_list', ['val1'])
        expect_type_de_champ_values('multiple_drop_down_list', ["val1, val2"])
        expect_type_de_champ_values('linked_drop_down_list', ["categorie 1;choix 1"])
        expect_type_de_champ_values('yes_no', ['Oui'])
        expect_type_de_champ_values('annuaire_education', [nil])
        expect_type_de_champ_values('rna', ["W173847273", "postal_code", "city_name", "departement_code", "region_name"])
        expect_type_de_champ_values('rnf', ['075-FDD-00003-01', "postal_code", "city_name", "departement_code", "region_name"])
        expect_type_de_champ_values('carte', ["\n"])
        expect_type_de_champ_values('cnaf', [nil])
        expect_type_de_champ_values('dgfip', [nil])
        expect_type_de_champ_values('pole_emploi', [nil])
        expect_type_de_champ_values('mesri', [nil])
        expect_type_de_champ_values('cojo', [nil])
        expect_type_de_champ_values('expression_reguliere', [nil])
      end
    end
  end
end
