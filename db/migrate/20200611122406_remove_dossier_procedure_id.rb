class RemoveDossierProcedureId < ActiveRecord::Migration[5.2]
  def change
    remove_column :dossiers, :procedure_id
  end
end
