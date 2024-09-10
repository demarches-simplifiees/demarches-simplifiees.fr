# frozen_string_literal: true

class AddPiecesJointesUpdatesToDossiers < ActiveRecord::Migration[7.0]
  def change
    add_column :dossiers, :last_champ_piece_jointe_updated_at, :datetime
    add_column :dossiers, :last_commentaire_piece_jointe_updated_at, :datetime
  end
end
