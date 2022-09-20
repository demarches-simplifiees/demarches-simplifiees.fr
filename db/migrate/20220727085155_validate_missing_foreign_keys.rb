class ValidateMissingForeignKeys < ActiveRecord::Migration[6.1]
  def change
    validate_foreign_key :champs, :dossiers
    validate_foreign_key :champs, :types_de_champ
    validate_foreign_key :champs, :etablissements
    validate_foreign_key :etablissements, :dossiers
  end
end
