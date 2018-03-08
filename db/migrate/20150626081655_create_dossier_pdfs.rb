class CreateDossierPdfs < ActiveRecord::Migration[5.2]
  def change
    create_table :dossier_pdfs do |t|
      t.string :ref_dossier_pdf
    end
    add_reference :dossier_pdfs, :dossier, references: :dossiers
  end
end
