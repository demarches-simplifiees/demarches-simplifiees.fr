# frozen_string_literal: true

class RemoveEmailColumnsFromAssignTos < ActiveRecord::Migration[7.2]
  def up
    safety_assured do
      remove_column :assign_tos, :instant_email_dossier_notifications_enabled
      remove_column :assign_tos, :instant_email_message_notifications_enabled
      remove_column :assign_tos, :instant_expert_avis_email_notifications_enabled
      remove_column :assign_tos, :daily_email_notifications_enabled
      remove_column :assign_tos, :weekly_email_notifications_enabled
    end
  end

  def down
    add_column :assign_tos, :instant_email_dossier_notifications_enabled, :boolean, default: false, null: false
    add_column :assign_tos, :instant_email_message_notifications_enabled, :boolean, default: false, null: false
    add_column :assign_tos, :instant_expert_avis_email_notifications_enabled, :boolean, default: false, null: false
    add_column :assign_tos, :daily_email_notifications_enabled, :boolean, default: false, null: false
    add_column :assign_tos, :weekly_email_notifications_enabled, :boolean, default: true, null: false
  end
end
