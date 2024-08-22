# frozen_string_literal: true

class AddGroupeInstructeurColumnToAssignTos < ActiveRecord::Migration[5.2]
  def change
    add_reference :assign_tos, :groupe_instructeur, foreign_key: true
    add_index :assign_tos, [:groupe_instructeur_id, :instructeur_id], unique: true, name: 'unique_couple_groupe_instructeur_instructeur'
  end
end
