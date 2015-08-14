class RenameEvenementVieFromDemarcheIntoEvenementVieId < ActiveRecord::Migration
  def change
    rename_column :formulaires, :evenement_vie, :evenement_vie_id
  end
end
