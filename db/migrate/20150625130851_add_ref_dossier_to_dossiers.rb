class AddRefDossierToDossiers < ActiveRecord::Migration[5.2]
  def change
    add_column :dossiers, :ref_dossier, :string
  end
end
