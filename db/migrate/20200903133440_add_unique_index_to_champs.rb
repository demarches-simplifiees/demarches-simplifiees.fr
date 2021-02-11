class AddUniqueIndexToChamps < ActiveRecord::Migration[6.0]
  def change
    add_index :champs, [:type_de_champ_id, :dossier_id, :row], unique: true
  end
end
