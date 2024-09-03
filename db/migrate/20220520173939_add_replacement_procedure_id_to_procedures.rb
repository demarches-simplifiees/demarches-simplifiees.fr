# frozen_string_literal: true

class AddReplacementProcedureIdToProcedures < ActiveRecord::Migration[6.1]
  def change
    add_column :procedures, :replaced_by_procedure_id, :bigint, foreign_key: { to_table: :procedures }
  end
end
