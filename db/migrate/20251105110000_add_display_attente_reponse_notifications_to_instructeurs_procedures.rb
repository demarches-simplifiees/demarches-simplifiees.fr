# frozen_string_literal: true

class AddDisplayAttenteReponseNotificationsToInstructeursProcedures < ActiveRecord::Migration[7.2]
  def change
    add_column :instructeurs_procedures, :display_attente_reponse_notifications, :string, default: "followed", null: false
  end
end
