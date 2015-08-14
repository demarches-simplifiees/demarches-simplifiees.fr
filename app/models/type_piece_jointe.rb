class TypePieceJointe < ActiveRecord::Base

	# TODO: test this methods
  def self.get_liste_piece_jointe(formulaire)
    where ("\"CERFA\" = '#{formulaire.demarche_id}'")
  end

end
