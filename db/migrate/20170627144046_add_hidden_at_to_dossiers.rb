class AddHiddenAtToDossiers < ActiveRecord::Migration[5.2]
  def change
    add_column :dossiers, :hidden_at, :datetime
    add_index :dossiers, :hidden_at
  end
end
