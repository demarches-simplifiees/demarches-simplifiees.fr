class ChangeProcedureFilterAttrInGestionnaire < ActiveRecord::Migration[5.2]
  def change
    remove_column :gestionnaires, :procedure_filter
    add_column :gestionnaires, :procedure_filter, :integer, default: nil
  end
end
