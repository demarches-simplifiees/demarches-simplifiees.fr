class DossierPdf < ActiveRecord::Base
  belongs_to :dossier

  mount_uploader :ref_dossier_pdf, DossierPdfUploader
end
