# frozen_string_literal: true

class AddEmailPreferencesToInstructeursProcedure < ActiveRecord::Migration[7.2]
  def change
    add_column :instructeurs_procedures, :daily_email_summary, :boolean, default: false, null: false
    add_column :instructeurs_procedures, :weekly_email_summary, :boolean, default: false, null: false
    add_column :instructeurs_procedures, :instant_email_new_dossier, :boolean, default: false, null: false
    add_column :instructeurs_procedures, :instant_email_new_message, :boolean, default: false, null: false
    add_column :instructeurs_procedures, :instant_email_new_expert_avis, :boolean, default: false, null: false
  end
end
