# frozen_string_literal: true

class AddDailyEmailNotificationsEnabledToAssignTos < ActiveRecord::Migration[5.2]
  def change
    add_column :assign_tos, :daily_email_notifications_enabled, :boolean, default: false, null: false
  end
end
