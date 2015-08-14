class TypePieceJointe < ActiveRecord::Base

	# TODO: test this methods
  def self.get_liste_piece_jointe ref_formulaire
    where ("\"CERFA\" = '#{ref_formulaire.ref_demarche}'")
  end

end
