# frozen_string_literal: true

class AddWeeklyEmailNotificationsToAssignTos < ActiveRecord::Migration[5.2]
  def change
    add_column :assign_tos, :weekly_email_notifications_enabled, :boolean, default: true, null: false
  end
end
