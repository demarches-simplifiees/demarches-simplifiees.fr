class AddUniqConstraintOnGestionnaireDossierCouple < ActiveRecord::Migration[5.0]
  def up
    change_column_null :follows, :gestionnaire_id, false
    change_column_null :follows, :dossier_id, false
    add_index :follows, [:gestionnaire_id, :dossier_id], unique: true
  end
end
