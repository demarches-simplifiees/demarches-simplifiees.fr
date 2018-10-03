class ResetAllPreferenceListDossier < ActiveRecord::Migration
  class PreferenceListDossier < ApplicationRecord
    belongs_to :gestionnaire
    belongs_to :procedure

    def self.available_columns_for(procedure_id = nil)
      columns = {
        dossier: columns_dossier,
        procedure: columns_procedure,
        entreprise: columns_entreprise,
        etablissement: columns_etablissement,
        user: columns_user,
        france_connect: columns_france_connect
      }
      columns
    end

    private

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

    def self.columns_france_connect
      table = 'france_connect_information'

      {
        gender: create_column('Civilité (FC)', table, 'gender', 'gender_fr', 1),
        given_name: create_column('Prénom (FC)', table, 'given_name', 'given_name', 2),
        family_name: create_column('Nom (FC)', table, 'family_name', 'family_name', 2)
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

  class Gestionnaire < ApplicationRecord
    has_many :assign_to, dependent: :destroy
    has_many :procedures, through: :assign_to

    def build_default_preferences_list_dossier(procedure_id = nil)
      PreferenceListDossier.available_columns_for(procedure_id).each do |table|
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
              procedure_id: procedure_id,
              gestionnaire: self
            )
          end
        end
      end
    end

    private

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

  class Procedure < ApplicationRecord
    has_many :assign_to, dependent: :destroy
    has_many :gestionnaires, through: :assign_to
  end

  def change
    PreferenceListDossier.delete_all

    Procedure.all.each do |procedure|
      procedure.gestionnaires.each do |gestionnaire|
        gestionnaire.build_default_preferences_list_dossier procedure.id
      end
    end

    Gestionnaire.all.each(&:build_default_preferences_list_dossier)
  end
end
