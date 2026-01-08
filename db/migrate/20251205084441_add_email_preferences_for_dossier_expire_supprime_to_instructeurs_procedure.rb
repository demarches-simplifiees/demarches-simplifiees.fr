# frozen_string_literal: true

class AddEmailPreferencesForDossierExpireSupprimeToInstructeursProcedure < ActiveRecord::Migration[7.2]
  def change
    add_column :instructeurs_procedures, :instant_email_dossier_expiration, :boolean, default: true, null: false
    add_column :instructeurs_procedures, :instant_email_dossier_expired, :boolean, default: true, null: false
    add_column :instructeurs_procedures, :instant_email_dossier_deletion, :boolean, default: true, null: false
  end
end
