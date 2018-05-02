class RemoveParentProcedureForeignKey < ActiveRecord::Migration[5.2]
  def change
    remove_foreign_key :procedures, column: "parent_procedure_id"
  end
end
