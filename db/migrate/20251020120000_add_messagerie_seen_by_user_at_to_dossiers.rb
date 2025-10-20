# frozen_string_literal: true

class AddMessagerieSeenByUserAtToDossiers < ActiveRecord::Migration[7.2]
  def change
    add_column :dossiers, :messagerie_seen_by_user_at, :datetime
  end
end
