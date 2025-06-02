# frozen_string_literal: true

class AddGroupeInstructeurIdColumnToDossier < ActiveRecord::Migration[5.2]
  def change
    add_reference :dossiers, :groupe_instructeur, foreign_key: true
  end
end
