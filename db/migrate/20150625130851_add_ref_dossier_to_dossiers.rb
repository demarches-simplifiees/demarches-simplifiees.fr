class AddRefDossierToDossiers < ActiveRecord::Migration
  def change
    add_column :dossiers, :ref_dossier, :string
  end
end
