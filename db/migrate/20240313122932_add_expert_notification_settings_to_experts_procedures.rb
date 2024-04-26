class AddExpertNotificationSettingsToExpertsProcedures < ActiveRecord::Migration[7.0]
  def change
    add_column :experts_procedures, :notify_on_new_avis, :boolean, default: true, null: false
    add_column :experts_procedures, :notify_on_new_message, :boolean, default: false, null: false
  end
end
