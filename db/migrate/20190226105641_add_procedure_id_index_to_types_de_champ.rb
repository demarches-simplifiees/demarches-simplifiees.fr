class AddProcedureIdIndexToTypesDeChamp < ActiveRecord::Migration[5.2]
  def change
    add_index :types_de_champ, :procedure_id
  end
end
