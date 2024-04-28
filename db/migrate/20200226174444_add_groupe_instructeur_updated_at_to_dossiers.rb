# frozen_string_literal: true

class AddGroupeInstructeurUpdatedAtToDossiers < ActiveRecord::Migration[5.2]
  def change
    add_column :dossiers, :groupe_instructeur_updated_at, :timestamp
  end
end
