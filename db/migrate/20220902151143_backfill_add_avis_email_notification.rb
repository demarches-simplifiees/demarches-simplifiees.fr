# frozen_string_literal: true

class BackfillAddAvisEmailNotification < ActiveRecord::Migration[6.1]
  def up
    AssignTo.in_batches do |relation|
      relation.update_all instant_expert_avis_email_notifications_enabled: false
      sleep(0.01)
    end

    add_check_constraint :assign_tos, "instant_expert_avis_email_notifications_enabled IS NOT NULL", name: "assign_tos_instant_expert_avis_email_notifications_enabled_null", validate: false
  end
end
