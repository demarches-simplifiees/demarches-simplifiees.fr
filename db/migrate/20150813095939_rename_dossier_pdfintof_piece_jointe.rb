class RenameDossierPdfintofPieceJointe < ActiveRecord::Migration
  def change
  	rename_table :dossier_pdfs, :pieces_jointes
  end
end
