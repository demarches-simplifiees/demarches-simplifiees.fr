class RenameFormulaireIdToProcedureId < ActiveRecord::Migration[5.2]
  def change
    rename_column :dossiers, :formulaire_id, :procedure_id
  end
end
