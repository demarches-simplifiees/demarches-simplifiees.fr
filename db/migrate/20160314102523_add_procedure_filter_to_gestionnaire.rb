class AddProcedureFilterToGestionnaire < ActiveRecord::Migration
  def change
    add_column :gestionnaires, :procedure_filter, :integer, array: true, default: []
  end
end
