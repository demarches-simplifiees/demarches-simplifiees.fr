# frozen_string_literal: true

class CreateTraitements < ActiveRecord::Migration[5.2]
  def change
    create_table :traitements do |t|
      t.references :dossier, foreign_key: true
      t.references :instructeur, foreign_key: true
      t.string :motivation
      t.string :state
      t.timestamp :processed_at
    end
  end
end
