# frozen_string_literal: true

class AddLastChampInstructeurUpdatedAt < ActiveRecord::Migration[7.2]
  def change
    add_column :dossiers, :last_champ_instructeur_updated_at, :datetime
  end
end
