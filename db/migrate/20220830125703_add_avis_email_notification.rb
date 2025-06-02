# frozen_string_literal: true

class AddAvisEmailNotification < ActiveRecord::Migration[6.1]
  def up
    add_column :assign_tos, :instant_expert_avis_email_notifications_enabled, :boolean
    change_column_default :assign_tos, :instant_expert_avis_email_notifications_enabled, false
  end

  def down
    remove_column :assign_tos, :instant_expert_avis_email_notifications_enabled
  end
end
