# frozen_string_literal: true

describe Column do
  describe 'get_value' do
    let(:groupe_instructeur) { create(:groupe_instructeur, instructeurs: [create(:instructeur)]) }

    context 'when dossier columns' do
      context 'when procedure for individual' do
        let(:individual) { create(:individual, nom: "Sim", prenom: "Paul", gender: 'M.') }
        let(:procedure) { create(:procedure, for_individual: true, groupe_instructeurs: [groupe_instructeur]) }
        let(:dossier) { create(:dossier, individual:, mandataire_first_name: "Martin", mandataire_last_name: "Christophe", for_tiers: true) }

        it 'retrieve individual information' do
          expect(procedure.find_column(label: "Prénom").get_value(dossier)).to eq("Paul")
          expect(procedure.find_column(label: "Nom").get_value(dossier)).to eq("Sim")
          expect(procedure.find_column(label: "Civilité").get_value(dossier)).to eq("M.")
        end
      end

      context 'when procedure for entreprise' do
        let(:procedure) { create(:procedure, for_individual: false, groupe_instructeurs: [groupe_instructeur]) }
        let(:dossier) { create(:dossier, :en_instruction, :with_entreprise, procedure:) }

        it 'retrieve entreprise information' do
          expect(procedure.find_column(label: "Libellé NAF").get_value(dossier)).to eq('Transports par conduites')
        end
      end

      context 'when sva/svr enabled' do
        let(:procedure) { create(:procedure, :sva, for_individual: true, groupe_instructeurs: [groupe_instructeur]) }
        let(:dossier) { create(:dossier, :en_instruction, procedure:) }

        it 'does not fail' do
          expect(procedure.find_column(label: "Date décision SVA").get_value(dossier)).to eq(nil)
        end
      end
    end

    context 'when champ columns' do
      let(:procedure) { create(:procedure, :with_all_champs_mandatory, groupe_instructeurs: [groupe_instructeur]) }
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
        expect_type_de_champ_values('carte', [nil])
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
    expect(columns.map { _1.get_value(champ) }).to eq(values)
  end

  def retrieve_champ(type)
    type_de_champ = types_de_champ.find { _1.type_champ == type }
    dossier.send(:filled_champ, type_de_champ, nil)
  end
end
