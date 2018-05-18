class AddUniqueIndexToServices < ActiveRecord::Migration[5.2]
  def change
    add_index :services, [:administrateur_id, :nom], unique: true
  end
end
