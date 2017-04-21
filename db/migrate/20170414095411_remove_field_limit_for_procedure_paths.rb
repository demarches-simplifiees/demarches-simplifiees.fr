class RemoveFieldLimitForProcedurePaths < ActiveRecord::Migration[5.0]
  def change
    change_column :procedure_paths, :path, :string, limit: nil, null: true, unique: true, index: true
  end
end
