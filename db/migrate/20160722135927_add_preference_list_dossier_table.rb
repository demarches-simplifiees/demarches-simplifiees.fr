class AddPreferenceListDossierTable < ActiveRecord::Migration[5.2]
  def change
    create_table :preference_list_dossiers do |t|
      t.string :libelle
      t.string :table
      t.string :attr
      t.string :attr_decorate
      t.string :bootstrap_lg
      t.string :order
      t.string :filter
    end

    add_belongs_to :preference_list_dossiers, :gestionnaire
  end
end
