class BuildDefaultPreferenceListDossier < ActiveRecord::Migration
  class Gestionnaire < ApplicationRecord
    def build_default_preferences_list_dossier
      PreferenceListDossier.available_columns.each do |table|
        table.second.each do |column|
          if valid_couple_table_attr? table.first, column.first
            PreferenceListDossier.create(
              libelle: column.second[:libelle],
              table: column.second[:table],
              attr: column.second[:attr],
              attr_decorate: column.second[:attr_decorate],
              bootstrap_lg: column.second[:bootstrap_lg],
              order: nil,
              filter: nil,
              gestionnaire_id: self.id
            )
          end
        end
      end
    end

    def valid_couple_table_attr?(table, column)
      couples = [
        {
          table: :dossier,
          column: :dossier_id
        },
        {
          table: :procedure,
          column: :libelle
        },
        {
          table: :etablissement,
          column: :siret
        },
        {
          table: :entreprise,
          column: :raison_sociale
        },
        {
          table: :dossier,
          column: :state
        }
      ]

      couples.include?({ table: table, column: column })
    end
  end

  class PreferenceListDossier < ApplicationRecord
    def self.available_columns
      {
        dossier: columns_dossier,
        procedure: columns_procedure,
        entreprise: columns_entreprise,
        etablissement: columns_etablissement,
        user: columns_user
      }
    end

    def self.columns_dossier
      table = nil

      {
        dossier_id: create_column('ID', table, 'id', 'id', 1),
        created_at: create_column('Créé le', table, 'created_at', 'first_creation', 2),
        updated_at: create_column('Mise à jour le', table, 'updated_at', 'last_update', 2),
        state: create_column('Statut', table, 'state', 'display_state', 1)
      }
    end

    def self.columns_procedure
      table = 'procedure'

      {
        libelle: create_column('Libellé démarche', table, 'libelle', 'libelle', 4),
        organisation: create_column('Organisation', table, 'organisation', 'organisation', 3),
        direction: create_column('Direction', table, 'direction', 'direction', 3)
      }
    end

    def self.columns_entreprise
      table = 'entreprise'

      {
        siren: create_column('SIREN', table, 'siren', 'siren', 2),
        forme_juridique: create_column('Forme juridique', table, 'forme_juridique', 'forme_juridique', 3),
        nom_commercial: create_column('Nom commercial', table, 'nom_commercial', 'nom_commercial', 3),
        raison_sociale: create_column('Raison sociale', table, 'raison_sociale', 'raison_sociale', 3),
        siret_siege_social: create_column('SIRET siège social', table, 'siret_siege_social', 'siret_siege_social', 2),
        date_creation: create_column('Date de création', table, 'date_creation', 'date_creation', 2)
      }
    end

    def self.columns_etablissement
      table = 'etablissement'

      {
        siret: create_column('SIRET', table, 'siret', 'siret', 2),
        libelle: create_column('Nom établissement', table, 'libelle_naf', 'libelle_naf', 3),
        code_postal: create_column('Code postal', table, 'code_postal', 'code_postal', 1)
      }
    end

    def self.columns_user
      table = 'user'

      {
        email: create_column('Email', table, 'email', 'email', 2)
      }
    end

    def self.create_column(libelle, table, attr, attr_decorate, bootstrap_lg)
      {
        libelle: libelle,
        table: table,
        attr: attr,
        attr_decorate: attr_decorate,
        bootstrap_lg: bootstrap_lg,
        order: nil,
        filter: nil
      }
    end
  end

  def up
    Gestionnaire.all.each(&:build_default_preferences_list_dossier)
  end

  def down
    Gestionnaire.all.each do |gestionnaire|
      PreferenceListDossier.where(gestionnaire_id: gestionnaire.id).delete_all
    end
  end
end
