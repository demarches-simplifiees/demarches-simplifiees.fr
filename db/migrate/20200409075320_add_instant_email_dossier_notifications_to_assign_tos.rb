# frozen_string_literal: true

class AddInstantEmailDossierNotificationsToAssignTos < ActiveRecord::Migration[5.2]
  def change
    add_column :assign_tos, :instant_email_dossier_notifications_enabled, :boolean, default: false, null: false
  end
end
