# frozen_string_literal: true

class AddUniqueIndexToExpertsProcedures < ActiveRecord::Migration[6.0]
  def change
    add_index :experts_procedures, [:expert_id, :procedure_id], unique: true
  end
end
