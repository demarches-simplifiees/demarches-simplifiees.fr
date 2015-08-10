class AddRefFormulaireToDossier < ActiveRecord::Migration
  def change
    add_column :dossiers, :ref_formulaire, :string
  end
end
