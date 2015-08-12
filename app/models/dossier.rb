class Dossier < ActiveRecord::Base
  has_one :etablissement
  has_one :entreprise
  has_many :dossier_pdf
  has_many :commentaires

  def get_pj piece_jointe_id
    dossier_pdf.where(ref_pieces_jointes_id: piece_jointe_id).last
  end
end
