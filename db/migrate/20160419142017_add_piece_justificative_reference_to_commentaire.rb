class AddPieceJustificativeReferenceToCommentaire < ActiveRecord::Migration[5.2]
  def change
    add_reference :commentaires, :piece_justificative, references: :piece_justificatives
  end
end
