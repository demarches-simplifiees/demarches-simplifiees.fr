class DossierPdf < ActiveRecord::Base
  belongs_to :dossier

  mount_uploader :ref_dossier_pdf, DossierPdfUploader

  def self.get_array_id_pj_valid_for_dossier dossier_id
    @array_id_pj_valides = Array.new

    DossierPdf.where(dossier_id: dossier_id).each do |pj_valide|
      @array_id_pj_valides << pj_valide.ref_pieces_jointes_id
    end

    @array_id_pj_valides
  end
end
