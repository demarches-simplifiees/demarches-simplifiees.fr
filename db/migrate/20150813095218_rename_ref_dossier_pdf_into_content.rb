class RenameRefDossierPdfIntoContent < ActiveRecord::Migration
  def change
    rename_column :dossier_pdfs, :ref_dossier_pdf, :content
  end
end
