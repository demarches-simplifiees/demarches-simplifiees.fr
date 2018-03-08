class RenameRefDossierPdfIntoContent < ActiveRecord::Migration[5.2]
  def change
    rename_column :dossier_pdfs, :ref_dossier_pdf, :content
  end
end
