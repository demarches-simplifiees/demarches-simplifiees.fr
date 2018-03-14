class AddRefFormulaireToDossier < ActiveRecord::Migration[5.2]
  def change
    add_column :dossiers, :ref_formulaire, :string
  end
end
