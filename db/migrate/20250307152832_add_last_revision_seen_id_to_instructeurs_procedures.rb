# frozen_string_literal: true

class AddLastRevisionSeenIdToInstructeursProcedures < ActiveRecord::Migration[7.0]
  def change
    add_column :instructeurs_procedures, :last_revision_seen_id, :bigint
  end
end
