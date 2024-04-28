# frozen_string_literal: true

class RemoveEmailNotificationsEnabledFromAssignTos < ActiveRecord::Migration[5.2]
  def change
    remove_column :assign_tos, :email_notifications_enabled
  end
end
