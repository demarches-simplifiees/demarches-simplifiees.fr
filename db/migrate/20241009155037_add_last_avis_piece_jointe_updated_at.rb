# frozen_string_literal: true

class AddLastAvisPieceJointeUpdatedAt < ActiveRecord::Migration[7.0]
  def change
    add_column :dossiers, :last_avis_piece_jointe_updated_at, :datetime
  end
end
