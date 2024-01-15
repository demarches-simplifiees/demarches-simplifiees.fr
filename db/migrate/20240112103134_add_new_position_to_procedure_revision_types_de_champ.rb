class AddNewPositionToProcedureRevisionTypesDeChamp < ActiveRecord::Migration[7.0]
  def change
    add_column :procedure_revision_types_de_champ, :new_position, :float
  end
end
