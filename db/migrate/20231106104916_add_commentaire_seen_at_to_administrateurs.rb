# frozen_string_literal: true

class AddCommentaireSeenAtToAdministrateurs < ActiveRecord::Migration[7.0]
  def change
    add_column :administrateurs, :commentaire_seen_at, :datetime
  end
end
