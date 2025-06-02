# frozen_string_literal: true

class AddCanonicalProcedureIdToProcedures < ActiveRecord::Migration[5.2]
  def change
    add_column :procedures, :canonical_procedure_id, :bigint
  end
end
