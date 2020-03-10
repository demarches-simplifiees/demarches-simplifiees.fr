class AddEmailNotificationEnabledToAssignTos < ActiveRecord::Migration[5.2]
  def change
    add_column :assign_tos, :email_notifications_enabled, :boolean, default: true, null: false
  end
end
