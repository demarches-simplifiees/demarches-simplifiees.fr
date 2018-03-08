class RenameRefFormulaireIntoFormulaire < ActiveRecord::Migration[5.2]
  def change
    rename_table :ref_formulaires, :formulaires
    rename_column :dossiers, :ref_formulaire_id, :formulaire_id
  end
end
