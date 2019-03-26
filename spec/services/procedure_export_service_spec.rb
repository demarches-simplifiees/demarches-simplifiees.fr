require 'spec_helper'

describe ProcedureExportService do
  describe 'to_data' do
    let(:procedure) { create(:procedure, :published, :with_all_champs) }
    let(:table) { :dossiers }
    subject { ProcedureExportService.new(procedure).to_data(table) }

    let(:headers) { subject[:headers] }
    let(:data) { subject[:data] }

    before do
      # change one tdc place to check if the header is ordered
      tdc_first = procedure.types_de_champ.first
      tdc_last = procedure.types_de_champ.last

      tdc_first.update(order_place: tdc_last.order_place + 1)
      procedure.reload
    end

    context 'dossiers' do
      it 'should have headers' do
        expect(headers).to eq([
          :id,
          :created_at,
          :updated_at,
          :archived,
          :email,
          :state,
          :initiated_at,
          :received_at,
          :processed_at,
          :motivation,
          :emails_instructeurs,
          :individual_gender,
          :individual_prenom,
          :individual_nom,
          :individual_birthdate,

          :textarea,
          :date,
          :datetime,
          :number,
          :decimal_number,
          :integer_number,
          :checkbox,
          :civilite,
          :email,
          :phone,
          :address,
          :yes_no,
          :simple_drop_down_list,
          :multiple_drop_down_list,
          :linked_drop_down_list,
          :pays,
          :nationalites,
          :regions,
          :departements,
          :engagement,
          :dossier_link,
          :piece_justificative,
          :siret,
          :carte,
          :text,

          :etablissement_siret,
          :etablissement_siege_social,
          :etablissement_naf,
          :etablissement_libelle_naf,
          :etablissement_adresse,
          :etablissement_numero_voie,
          :etablissement_type_voie,
          :etablissement_nom_voie,
          :etablissement_complement_adresse,
          :etablissement_code_postal,
          :etablissement_localite,
          :etablissement_code_insee_localite,
          :entreprise_siren,
          :entreprise_capital_social,
          :entreprise_numero_tva_intracommunautaire,
          :entreprise_forme_juridique,
          :entreprise_forme_juridique_code,
          :entreprise_nom_commercial,
          :entreprise_raison_sociale,
          :entreprise_siret_siege_social,
          :entreprise_code_effectif_entreprise,
          :entreprise_date_creation,
          :entreprise_nom,
          :entreprise_prenom
        ])
      end

      it 'should have empty values' do
        expect(data).to eq([[]])
      end

      context 'with dossier' do
        let!(:dossier) { create(:dossier, :en_instruction, :with_all_champs, :for_individual, procedure: procedure) }

        let(:dossier_data) {
          [
            dossier.id.to_s,
            dossier.created_at.to_s,
            dossier.updated_at.to_s,
            "false",
            dossier.user.email,
            "received",
            dossier.en_construction_at.to_s,
            dossier.en_instruction_at.to_s,
            nil,
            nil,
            nil
          ] + individual_data
        }

        let(:individual_data) {
          [
            "M.",
            "Xavier",
            "Julien",
            "1991-11-01"
          ]
        }

        let(:champs_data) {
          dossier.reload.champs.reject(&:exclude_from_export?).map(&:for_export)
        }

        let(:etablissement_data) {
          Array.new(24)
        }

        it 'should have values' do
          dossier_end = dossier_data.length
          data_end = dossier_end + champs_data.length
          etab_end = data_end + etablissement_data.length
          expect(data.first[0...dossier_end]).to eq(dossier_data)
          data.first[dossier_end...data_end].map.with_index { |d, i|
            puts d.to_s + '=' + champs_data[i]&.to_s if (d)
            expect(d).to eq(champs_data[i])
          }
          expect(data.first[dossier_end...data_end]).to eq(champs_data)
          expect(data.first[data_end...etab_end]).to eq(etablissement_data)

          expect(data).to eq([
            dossier_data + champs_data + etablissement_data
          ])
        end

        context 'and etablissement' do
          let!(:dossier) { create(:dossier, :en_instruction, :with_all_champs, :with_entreprise, procedure: procedure) }

          let(:etablissement_data) {
            [
              dossier.etablissement.siret,
              dossier.etablissement.siege_social.to_s,
              dossier.etablissement.naf,
              dossier.etablissement.libelle_naf,
              dossier.etablissement.adresse&.chomp&.gsub("\r\n", ' ')&.delete("\r"),
              dossier.etablissement.numero_voie,
              dossier.etablissement.type_voie,
              dossier.etablissement.nom_voie,
              dossier.etablissement.complement_adresse,
              dossier.etablissement.code_postal,
              dossier.etablissement.localite,
              dossier.etablissement.code_insee_localite,
              dossier.etablissement.entreprise_siren,
              dossier.etablissement.entreprise_capital_social.to_s,
              dossier.etablissement.entreprise_numero_tva_intracommunautaire,
              dossier.etablissement.entreprise_forme_juridique,
              dossier.etablissement.entreprise_forme_juridique_code,
              dossier.etablissement.entreprise_nom_commercial,
              dossier.etablissement.entreprise_raison_sociale,
              dossier.etablissement.entreprise_siret_siege_social,
              dossier.etablissement.entreprise_code_effectif_entreprise,
              dossier.etablissement.entreprise_date_creation.to_datetime.to_s,
              dossier.etablissement.entreprise_nom,
              dossier.etablissement.entreprise_prenom
            ]
          }

          let(:individual_data) {
            Array.new(4)
          }

          it 'should have values' do
            dossier_end = dossier_data.length
            data_end = dossier_end + champs_data.length
            etab_end = data_end + etablissement_data.length
            expect(data.first[0...dossier_end]).to eq(dossier_data)
            expect(data.first[dossier_end...data_end]).to eq(champs_data)
            expect(data.first[data_end...etab_end]).to eq(etablissement_data)

            expect(data).to eq([
              dossier_data + champs_data + etablissement_data
            ])
          end
        end
      end
    end

    context 'etablissements' do
      let(:table) { :etablissements }

      it 'should have headers' do
        expect(headers).to eq([
          :dossier_id,
          :libelle,
          :etablissement_siret,
          :etablissement_siege_social,
          :etablissement_naf,
          :etablissement_libelle_naf,
          :etablissement_adresse,
          :etablissement_numero_voie,
          :etablissement_type_voie,
          :etablissement_nom_voie,
          :etablissement_complement_adresse,
          :etablissement_code_postal,
          :etablissement_localite,
          :etablissement_code_insee_localite,
          :entreprise_siren,
          :entreprise_capital_social,
          :entreprise_numero_tva_intracommunautaire,
          :entreprise_forme_juridique,
          :entreprise_forme_juridique_code,
          :entreprise_nom_commercial,
          :entreprise_raison_sociale,
          :entreprise_siret_siege_social,
          :entreprise_code_effectif_entreprise,
          :entreprise_date_creation,
          :entreprise_nom,
          :entreprise_prenom
        ])
      end

      it 'should have empty values' do
        expect(data).to eq([[]])
      end

      context 'with dossier containing champ siret' do
        let!(:dossier) { create(:dossier, :en_instruction, :with_all_champs, procedure: procedure) }
        let(:etablissement) { dossier.champs.find { |champ| champ.type_champ == 'siret' }.etablissement }

        let(:etablissement_data) {
          [
            dossier.id,
            'siret',
            etablissement.siret,
            etablissement.siege_social.to_s,
            etablissement.naf,
            etablissement.libelle_naf,
            etablissement.adresse&.chomp&.gsub("\r\n", ' ')&.delete("\r"),
            etablissement.numero_voie,
            etablissement.type_voie,
            etablissement.nom_voie,
            etablissement.complement_adresse,
            etablissement.code_postal,
            etablissement.localite,
            etablissement.code_insee_localite,
            etablissement.entreprise_siren,
            etablissement.entreprise_capital_social.to_s,
            etablissement.entreprise_numero_tva_intracommunautaire,
            etablissement.entreprise_forme_juridique,
            etablissement.entreprise_forme_juridique_code,
            etablissement.entreprise_nom_commercial,
            etablissement.entreprise_raison_sociale,
            etablissement.entreprise_siret_siege_social,
            etablissement.entreprise_code_effectif_entreprise,
            etablissement.entreprise_date_creation.to_datetime.to_s,
            etablissement.entreprise_nom,
            etablissement.entreprise_prenom
          ]
        }

        it 'should have values' do
          expect(data.first).to eq(etablissement_data)
        end
      end
    end
  end
end
