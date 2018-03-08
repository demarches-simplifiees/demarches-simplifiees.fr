class RemoveFieldLimitForProcedurePaths < ActiveRecord::Migration[5.2]
  def change
    change_column :procedure_paths, :path, :string, limit: nil, null: true, unique: true, index: true
  end
end
