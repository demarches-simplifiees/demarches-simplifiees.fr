class AddUniqueIndexOnAssignTosGestionnaireIdProcedureId < ActiveRecord::Migration[5.2]
  def change
    add_index :assign_tos, [:gestionnaire_id, :procedure_id], unique: true
  end
end
