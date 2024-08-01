# frozen_string_literal: true

class RemoveTypeDeChampProcedureId < ActiveRecord::Migration[6.0]
  def change
    remove_column :types_de_champ, :procedure_id
  end
end
