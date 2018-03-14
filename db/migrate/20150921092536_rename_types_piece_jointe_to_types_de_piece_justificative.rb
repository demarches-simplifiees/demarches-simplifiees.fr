class RenameTypesPieceJointeToTypesDePieceJustificative < ActiveRecord::Migration[5.2]
  def change
    remove_column :types_piece_jointe, :CERFA
    remove_column :types_piece_jointe, :nature
    remove_column :types_piece_jointe, :libelle_complet
    remove_column :types_piece_jointe, :etablissement
    remove_column :types_piece_jointe, :demarche
    remove_column :types_piece_jointe, :administration_emetrice

    rename_column :types_piece_jointe, :formulaire_id, :procedure_id

    rename_table :types_piece_jointe, :types_de_piece_justificative

    rename_column :pieces_justificatives, :type_piece_jointe_id, :type_de_piece_justificative_id
  end
end
