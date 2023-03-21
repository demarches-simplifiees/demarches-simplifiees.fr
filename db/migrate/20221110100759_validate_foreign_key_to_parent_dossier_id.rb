class ValidateForeignKeyToParentDossierId < ActiveRecord::Migration[6.1]
  def change
    validate_foreign_key "dossiers", "dossiers"
  end
end
