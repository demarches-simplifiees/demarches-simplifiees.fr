# frozen_string_literal: true

class GestionnaireToInstructeur < ActiveRecord::Migration[5.2]
  def change
    rename_table :gestionnaires, :instructeurs

    rename_table :administrateurs_gestionnaires, :administrateurs_instructeurs
    rename_column :administrateurs_instructeurs, :gestionnaire_id, :instructeur_id
    rename_index :administrateurs_instructeurs, :unique_couple_administrateur_gestionnaire, :unique_couple_administrateur_instructeur

    rename_column :assign_tos, :gestionnaire_id, :instructeur_id

    rename_column :avis, :gestionnaire_id, :instructeur_id

    rename_column :commentaires, :gestionnaire_id, :instructeur_id

    rename_column :dossier_operation_logs, :gestionnaire_id, :instructeur_id

    rename_column :follows, :gestionnaire_id, :instructeur_id

    rename_column :trusted_device_tokens, :gestionnaire_id, :instructeur_id
  end
end
