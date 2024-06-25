# frozen_string_literal: true

class ChangeTypesDeChampMandatoryDefault < ActiveRecord::Migration[7.0]
  def change
    change_column_default :types_de_champ, :mandatory, from: false, to: true
  end
end
