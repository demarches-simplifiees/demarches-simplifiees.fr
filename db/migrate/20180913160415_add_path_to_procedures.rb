class AddPathToProcedures < ActiveRecord::Migration[5.2]
  def change
    add_column :procedures, :path, :string, index: true
  end
end
