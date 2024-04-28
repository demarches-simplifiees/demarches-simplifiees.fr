# frozen_string_literal: true

class AddForcedGroupeInstructeurToDossier < ActiveRecord::Migration[7.0]
  def change
    add_column :dossiers, :forced_groupe_instructeur, :boolean, default: false, null: false
  end
end
