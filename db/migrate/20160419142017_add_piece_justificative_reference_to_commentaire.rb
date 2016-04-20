class AddPieceJustificativeReferenceToCommentaire < ActiveRecord::Migration
  def change
    add_reference :commentaires, :piece_justificative, references: :piece_justificatives
  end
end
