class AddRefPiecesJointesRefToDossierPdf < ActiveRecord::Migration[5.2]
  def change
    add_reference :dossier_pdfs, :ref_pieces_jointes, index: true
  end
end
