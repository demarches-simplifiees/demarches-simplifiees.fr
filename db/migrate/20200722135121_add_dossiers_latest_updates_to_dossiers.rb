# frozen_string_literal: true

class AddDossiersLatestUpdatesToDossiers < ActiveRecord::Migration[6.0]
  def change
    add_column :dossiers, :last_champ_updated_at, :datetime
    add_column :dossiers, :last_champ_private_updated_at, :datetime
    add_column :dossiers, :last_avis_updated_at, :datetime
    add_column :dossiers, :last_commentaire_updated_at, :datetime
  end
end
