class AddProcedureFilterToGestionnaire < ActiveRecord::Migration[5.2]
  def change
    add_column :gestionnaires, :procedure_filter, :integer, array: true, default: []
  end
end
