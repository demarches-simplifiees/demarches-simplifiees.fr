class DropPreferenceListDossiers < ActiveRecord::Migration[5.2]
  def change
    drop_table :preference_list_dossiers
  end
end
