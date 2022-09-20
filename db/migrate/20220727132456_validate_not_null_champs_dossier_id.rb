class ValidateNotNullChampsDossierId < ActiveRecord::Migration[6.1]
  def change
    validate_check_constraint :champs, name: "champs_dossier_id_null"
    change_column_null :champs, :dossier_id, false
    remove_check_constraint :champs, name: "champs_dossier_id_null"
  end
end
