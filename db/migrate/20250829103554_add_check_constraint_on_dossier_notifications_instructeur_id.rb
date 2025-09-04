# frozen_string_literal: true

class AddCheckConstraintOnDossierNotificationsInstructeurId < ActiveRecord::Migration[7.1]
  def change
    add_check_constraint :dossier_notifications, "instructeur_id IS NOT NULL", name: "dossier_notifications_instructeur_id_null", validate: false
  end
end
