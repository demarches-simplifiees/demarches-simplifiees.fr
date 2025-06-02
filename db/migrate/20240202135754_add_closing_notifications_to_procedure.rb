# frozen_string_literal: true

class AddClosingNotificationsToProcedure < ActiveRecord::Migration[7.0]
  def change
    safety_assured do
      add_column :procedures, :closing_notification_brouillon, :boolean, default: false, null: false
      add_column :procedures, :closing_notification_en_cours, :boolean, default: false, null: false
    end
  end
end
