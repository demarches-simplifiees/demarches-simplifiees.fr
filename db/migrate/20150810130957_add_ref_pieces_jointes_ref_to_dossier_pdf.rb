class AddRefPiecesJointesRefToDossierPdf < ActiveRecord::Migration
  def change
    add_reference :dossier_pdfs, :ref_pieces_jointes, index: true
  end
end
