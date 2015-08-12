class RefPiecesJointe < ActiveRecord::Base

  def self.get_liste_piece_jointe ref_formulaire
    @formulaire = RefFormulaire.find(ref_formulaire)
    RefPiecesJointe.where ("\"CERFA\" = '#{@formulaire.ref_demarche}'")
  end

end
