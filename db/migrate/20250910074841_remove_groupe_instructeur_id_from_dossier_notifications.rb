# frozen_string_literal: true

class RemoveGroupeInstructeurIdFromDossierNotifications < ActiveRecord::Migration[7.1]
  def up
    safety_assured { remove_reference :dossier_notifications, :groupe_instructeur, foreign_key: true }
  end

  def down
    add_reference :dossier_notifications, :groupe_instructeur, foreign_key: true, null: true
  end
end
