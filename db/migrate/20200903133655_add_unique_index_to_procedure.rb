class AddUniqueIndexToProcedure < ActiveRecord::Migration[6.0]
  def change
    add_index :procedures, [:path, :closed_at, :hidden_at, :unpublished_at], unique: true, name: 'path_uniqueness'
  end
end
