# frozen_string_literal: true

describe Column do
  describe 'get_value' do
    let(:groupe_instructeur) { create(:groupe_instructeur, instructeurs: [create(:instructeur)]) }
    let(:export_template) { create(:export_template, groupe_instructeur:) }

    context 'when dossier columns' do
      before do
        export_template.exported_columns = (procedure.all_usager_columns_for_export + procedure.all_dossier_columns_for_export)
          .map { ExportedColumn.new(libelle: _1.label, column: _1) }
      end

      context 'when procedure for individual' do
        let(:individual) { create(:individual, nom: "Sim", prenom: "Paul", gender: 'M.') }
        let(:procedure) { create(:procedure, for_individual: true, groupe_instructeurs: [groupe_instructeur]) }
        let(:dossier) { create(:dossier, individual:, mandataire_first_name: "Martin", mandataire_last_name: "Christophe", for_tiers: true) }

        it 'retrieve individual information' do
          expect(procedure.find_column(label: "Prénom").get_value(dossier)).to eq("Paul")
          expect(procedure.find_column(label: "Nom").get_value(dossier)).to eq("Sim")
          expect(procedure.find_column(label: "Civilité").get_value(dossier)).to eq("M.")
          expect(procedure.find_column(label: "Dépôt pour un tiers").get_value(dossier)).to eq(true)
          expect(procedure.find_column(label: "Nom du mandataire").get_value(dossier)).to eq("Christophe")
          expect(procedure.find_column(label: "Prénom du mandataire").get_value(dossier)).to eq("Martin")
        end
      end

      context 'when procedure for entreprise' do
        let(:procedure) { create(:procedure, for_individual: false, groupe_instructeurs: [groupe_instructeur]) }
        let(:dossier) { create(:dossier, :en_instruction, :with_entreprise, procedure:) }

        it 'retrieve entreprise information' do
          expect(procedure.find_column(label: "Dossier ID").get_value(dossier)).to eq(dossier.id)
          expect(procedure.find_column(label: "Email").get_value(dossier)).to eq(dossier.user_email_for(:display))
          expect(procedure.find_column(label: "FranceConnect ?").get_value(dossier)).to eq(false)
          expect(procedure.find_column(label: "Entreprise forme juridique").get_value(dossier)).to eq("SA à conseil d'administration (s.a.i.)")
          expect(procedure.find_column(label: "Entreprise SIREN").get_value(dossier)).to eq('440117620')
          expect(procedure.find_column(label: "Entreprise nom commercial").get_value(dossier)).to eq('GRTGAZ')
          expect(procedure.find_column(label: "Entreprise raison sociale").get_value(dossier)).to eq('GRTGAZ')
          expect(procedure.find_column(label: "Entreprise SIRET siège social").get_value(dossier)).to eq('44011762001530')
          expect(procedure.find_column(label: "Date de création").get_value(dossier)).to eq(Date.parse('1990-04-24'))
          expect(procedure.find_column(label: "SIRET").get_value(dossier)).to eq('44011762001530')
          expect(procedure.find_column(label: "Libellé NAF").get_value(dossier)).to eq('Transports par conduites')
          expect(procedure.find_column(label: "Établissement code postal").get_value(dossier)).to eq('92270')
          expect(procedure.find_column(label: "Établissement siège social").get_value(dossier)).to eq(true)
          expect(procedure.find_column(label: "Établissement NAF").get_value(dossier)).to eq('4950Z')
          expect(procedure.find_column(label: "Établissement Adresse").get_value(dossier)).to eq("GRTGAZ\r IMMEUBLE BORA\r 6 RUE RAOUL NORDLING\r 92270 BOIS COLOMBES\r")
          expect(procedure.find_column(label: "Établissement numero voie").get_value(dossier)).to eq('6')
          expect(procedure.find_column(label: "Établissement type voie").get_value(dossier)).to eq('RUE')
          expect(procedure.find_column(label: "Établissement nom voie").get_value(dossier)).to eq('RAOUL NORDLING')
          expect(procedure.find_column(label: "Établissement complément adresse").get_value(dossier)).to eq('IMMEUBLE BORA')
          expect(procedure.find_column(label: "Établissement localité").get_value(dossier)).to eq('BOIS COLOMBES')
          expect(procedure.find_column(label: "Établissement code INSEE localité").get_value(dossier)).to eq('92009')
          expect(procedure.find_column(label: "Entreprise SIREN").get_value(dossier)).to eq('440117620')
          expect(procedure.find_column(label: "Entreprise capital social").get_value(dossier)).to eq(537_100_000)
          expect(procedure.find_column(label: "Entreprise numero TVA intracommunautaire").get_value(dossier)).to eq('FR27440117620')
          expect(procedure.find_column(label: "Entreprise forme juridique code").get_value(dossier)).to eq('5599')
          expect(procedure.find_column(label: "Entreprise code effectif entreprise").get_value(dossier)).to eq('51')
          expect(procedure.find_column(label: "Entreprise état administratif").get_value(dossier)).to eq("actif")
          expect(procedure.find_column(label: "Entreprise nom").get_value(dossier)).to eq(nil)
          expect(procedure.find_column(label: "Entreprise prénom").get_value(dossier)).to eq(nil)
          expect(procedure.find_column(label: "Association RNA").get_value(dossier)).to eq(nil)
          expect(procedure.find_column(label: "Association titre").get_value(dossier)).to eq(nil)
          expect(procedure.find_column(label: "Association objet").get_value(dossier)).to eq(nil)
          expect(procedure.find_column(label: "Association date de création").get_value(dossier)).to eq(nil)
          expect(procedure.find_column(label: "Association date de déclaration").get_value(dossier)).to eq(nil)
          expect(procedure.find_column(label: "Association date de publication").get_value(dossier)).to eq(nil)
          expect(procedure.find_column(label: "Créé le").get_value(dossier)).to be_an_instance_of(ActiveSupport::TimeWithZone)
          expect(procedure.find_column(label: "Mis à jour le").get_value(dossier)).to be_an_instance_of(ActiveSupport::TimeWithZone)
          expect(procedure.find_column(label: "Déposé le").get_value(dossier)).to be_an_instance_of(ActiveSupport::TimeWithZone)
          expect(procedure.find_column(label: "En construction le").get_value(dossier)).to be_an_instance_of(ActiveSupport::TimeWithZone)
          expect(procedure.find_column(label: "En instruction le").get_value(dossier)).to be_an_instance_of(ActiveSupport::TimeWithZone)
          expect(procedure.find_column(label: "Terminé le").get_value(dossier)).to eq(nil)
          expect(procedure.find_column(label: "Statut").get_value(dossier)).to eq('en_instruction')
          expect(procedure.find_column(label: "Archivé").get_value(dossier)).to eq(false)
          expect(procedure.find_column(label: "Motivation de la décision").get_value(dossier)).to eq(nil)
          expect(procedure.find_column(label: "Dernière mise à jour du dossier le").get_value(dossier)).to eq(nil)
          expect(procedure.find_column(label: "Email instructeur").get_value(dossier)).to eq('')
        end
      end

      context 'when procedure for entreprise which is also an association' do
        let(:procedure) { create(:procedure, for_individual: false, groupe_instructeurs: [groupe_instructeur]) }
        let(:etablissement) { create(:etablissement, :is_association) }
        let(:dossier) { create(:dossier, :en_instruction, procedure:, etablissement:) }

        it 'retrieve also association information' do
          expect(procedure.find_column(label: "Association RNA").get_value(dossier)).to eq("W072000535")
          expect(procedure.find_column(label: "Association titre").get_value(dossier)).to eq("ASSOCIATION POUR LA PROMOTION DE SPECTACLES AU CHATEAU DE ROCHEMAURE")
          expect(procedure.find_column(label: "Association objet").get_value(dossier)).to eq("mise en oeuvre et réalisation de spectacles au chateau de rochemaure")
          expect(procedure.find_column(label: "Association date de création").get_value(dossier)).to eq(Date.parse("1990-04-24"))
          expect(procedure.find_column(label: "Association date de déclaration").get_value(dossier)).to eq(Date.parse("2014-11-28"))
          expect(procedure.find_column(label: "Association date de publication").get_value(dossier)).to eq(Date.parse("1990-05-16"))
        end
      end
    end

    context 'when champ columns' do
      let(:procedure) { create(:procedure, :with_all_champs_mandatory, groupe_instructeurs: [groupe_instructeur]) }
      let(:dossier) { create(:dossier, :with_populated_champs, procedure:) }
      let(:types_de_champ) { procedure.all_revisions_types_de_champ }

      before do
        export_template.exported_columns = types_de_champ
          .flat_map { _1.columns(procedure_id: procedure.id) }
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

  private

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
end
