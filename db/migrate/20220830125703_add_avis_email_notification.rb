class AddAvisEmailNotification < ActiveRecord::Migration[6.1]
  def change
    add_column :assign_tos, :instant_expert_avis_email_notifications_enabled, :boolean, default: false, null: false
  end
end
