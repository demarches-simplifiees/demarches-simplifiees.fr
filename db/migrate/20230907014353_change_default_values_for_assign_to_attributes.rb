# frozen_string_literal: true

class ChangeDefaultValuesForAssignToAttributes < ActiveRecord::Migration[7.0]
  def change
    change_column_default :assign_tos, :instant_email_dossier_notifications_enabled, from: false, to: true
    change_column_default :assign_tos, :instant_email_message_notifications_enabled, from: false, to: true
    change_column_default :assign_tos, :weekly_email_notifications_enabled, from: true, to: false
  end
end
