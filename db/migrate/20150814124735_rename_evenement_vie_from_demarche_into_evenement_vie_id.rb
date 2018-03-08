class RenameEvenementVieFromDemarcheIntoEvenementVieId < ActiveRecord::Migration[5.2]
  def change
    rename_column :formulaires, :evenement_vie, :evenement_vie_id
  end
end
