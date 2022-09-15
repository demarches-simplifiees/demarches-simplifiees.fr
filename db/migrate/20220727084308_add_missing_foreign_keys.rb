class AddMissingForeignKeys < ActiveRecord::Migration[6.1]
  def change
    add_foreign_key :champs, :dossiers, validate: false
    add_foreign_key :champs, :types_de_champ, validate: false
    add_foreign_key :champs, :etablissements, validate: false
    add_foreign_key :etablissements, :dossiers, validate: false

    add_check_constraint :champs, "dossier_id IS NOT NULL", name: "champs_dossier_id_null", validate: false
    add_check_constraint :champs, "type_de_champ_id IS NOT NULL", name: "champs_type_de_champ_id_null", validate: false
  end
end
