class LinkTypePieceJointeToFormulaire < ActiveRecord::Migration
  # def up
  #   TypePieceJointe.find_each do |type_piece_jointe|
  #     forms = Formulaire.find_by_demarche_id(type_piece_jointe.CERFA)
  #     type_piece_jointe.update(formulaire_id: forms.id) if forms.present?
  #   end
  # end
end
