class RemoveProcedureFilterFromGestionnaires < ActiveRecord::Migration[5.2]
  def change
    remove_column :gestionnaires, :procedure_filter, :integer, default: nil
  end
end
