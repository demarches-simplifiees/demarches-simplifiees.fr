class FixRefFormulaireToDossier < ActiveRecord::Migration[5.2]
  def change
    remove_column :dossiers, :ref_formulaire, :integer
    add_reference :dossiers, :ref_formulaire, index: true
  end
end
