class AddReferentielForeignKeyToTypesDeChamp < ActiveRecord::Migration[7.0]
  def change
    add_foreign_key :types_de_champ, :referentiels, validate: false
  end
end
