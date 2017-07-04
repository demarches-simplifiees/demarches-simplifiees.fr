class AddHiddenAtToDossiers < ActiveRecord::Migration[5.0]
  def change
    add_column :dossiers, :hidden_at, :datetime
    add_index :dossiers, :hidden_at
  end
end
