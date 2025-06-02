# frozen_string_literal: true

class AddExpertNotificationSettingsToExpertsProcedures < ActiveRecord::Migration[7.0]
  def change
    safety_assured do
      add_column :experts_procedures, :notify_on_new_avis, :boolean, default: true, null: false
      add_column :experts_procedures, :notify_on_new_message, :boolean, default: false, null: false
    end
  end
end
