class RenameDossierPdfintofPieceJointe < ActiveRecord::Migration[5.2]
  def change
    rename_table :dossier_pdfs, :pieces_jointes
  end
end
