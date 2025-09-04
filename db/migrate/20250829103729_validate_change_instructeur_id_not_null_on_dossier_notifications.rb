# frozen_string_literal: true

class ValidateChangeInstructeurIdNotNullOnDossierNotifications < ActiveRecord::Migration[7.1]
  def up
    validate_check_constraint :dossier_notifications, name: "dossier_notifications_instructeur_id_null"
    change_column_null :dossier_notifications, :instructeur_id, false
    remove_check_constraint :dossier_notifications, name: "dossier_notifications_instructeur_id_null"
  end

  def down
    add_check_constraint :dossier_notifications, "instructeur_id IS NOT NULL", name: "dossier_notifications_instructeur_id_null", validate: false
    change_column_null :dossier_notifications, :instructeur_id, true
  end
end
