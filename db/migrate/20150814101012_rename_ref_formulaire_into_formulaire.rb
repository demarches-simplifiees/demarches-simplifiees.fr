class RenameRefFormulaireIntoFormulaire < ActiveRecord::Migration
  def change
    rename_table :ref_formulaires, :formulaires
    rename_column :dossiers, :ref_formulaire_id, :formulaire_id
  end
end
