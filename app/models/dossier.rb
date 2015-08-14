class Dossier < ActiveRecord::Base
  has_one :etablissement
  has_one :entreprise
  has_many :pieces_jointes
  belongs_to :ref_formulaire
  has_many :commentaires

  delegate :siren, to: :entreprise
  delegate :siret, to: :etablissement

  def get_pj piece_jointe_id
    pieces_jointes.where(type_piece_jointe_id: piece_jointe_id).last
  end

  def liste_piece_justificative
    ref_formulaire.liste_piece_justificative
  end
end
