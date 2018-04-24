class AddParentProcedureToProcedures < ActiveRecord::Migration[5.2]
  def change
    add_reference :procedures, :parent_procedure, foreign_key: { to_table: :procedures }
  end
end
