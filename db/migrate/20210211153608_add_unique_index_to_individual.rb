class AddUniqueIndexToIndividual < ActiveRecord::Migration[6.0]
  def change
    remove_index :individuals, :dossier_id
    add_index :individuals, :dossier_id, unique: true
  end
end
