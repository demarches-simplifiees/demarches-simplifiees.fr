class DropProcedurePaths < ActiveRecord::Migration[5.2]
  def change
    drop_table :procedure_paths
  end
end
