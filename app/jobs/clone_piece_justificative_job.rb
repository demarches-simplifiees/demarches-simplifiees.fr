class ClonePieceJustificativeJob < ApplicationJob
  def perform(from_champ, kopy_champ)
    from_champ.clone_piece_justificative(kopy_champ)
  end
end
