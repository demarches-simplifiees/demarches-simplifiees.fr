# frozen_string_literal: true

class AddInstantEmailMessageNotificationsToAssignTos < ActiveRecord::Migration[5.2]
  def change
    add_column :assign_tos, :instant_email_message_notifications_enabled, :boolean, default: false, null: false
  end
end
