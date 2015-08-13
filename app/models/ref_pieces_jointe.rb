class RefPiecesJointe < ActiveRecord::Base

	# TODO: test this methods
  def self.get_liste_piece_jointe ref_formulaire
    RefPiecesJointe.where ("\"CERFA\" = '#{ref_formulaire.ref_demarche}'")
  end

end
