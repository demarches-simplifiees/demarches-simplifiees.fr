class DropPreferenceListDossiers < ActiveRecord::Migration[5.0]
  def change
    drop_table :preference_list_dossiers
  end
end
