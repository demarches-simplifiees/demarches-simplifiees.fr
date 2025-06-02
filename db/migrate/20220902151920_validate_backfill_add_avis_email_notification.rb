# frozen_string_literal: true

class ValidateBackfillAddAvisEmailNotification < ActiveRecord::Migration[6.1]
  def change
    validate_check_constraint :assign_tos, name: "assign_tos_instant_expert_avis_email_notifications_enabled_null"
  end
end
