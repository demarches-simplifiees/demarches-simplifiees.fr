class RenameFormulaireIdToProcedureId < ActiveRecord::Migration
  def change
    rename_column :dossiers, :formulaire_id, :procedure_id
  end
end
