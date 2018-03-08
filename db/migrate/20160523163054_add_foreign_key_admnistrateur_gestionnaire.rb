class AddForeignKeyAdmnistrateurGestionnaire < ActiveRecord::Migration[5.2]
  def change
    add_index :administrateurs_gestionnaires, [:gestionnaire_id, :administrateur_id], unique: true, name: 'unique_couple_administrateur_gestionnaire'
  end
end
