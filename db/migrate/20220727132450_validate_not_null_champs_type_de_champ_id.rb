class ValidateNotNullChampsTypeDeChampId < ActiveRecord::Migration[6.1]
  def change
    validate_check_constraint :champs, name: "champs_type_de_champ_id_null"
    change_column_null :champs, :type_de_champ_id, false
    remove_check_constraint :champs, name: "champs_type_de_champ_id_null"
  end
end
