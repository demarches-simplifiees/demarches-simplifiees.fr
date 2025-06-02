# frozen_string_literal: true

class AddIndexesToDossier < ActiveRecord::Migration[5.2]
  def change
    add_index :dossiers, :state
    add_index :dossiers, :archived
    add_index :follows, :unfollowed_at
  end
end
