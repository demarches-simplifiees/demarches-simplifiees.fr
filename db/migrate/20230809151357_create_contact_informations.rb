# frozen_string_literal: true

class CreateContactInformations < ActiveRecord::Migration[7.0]
  def change
    create_table :contact_informations do |t|
      t.belongs_to :groupe_instructeur, null: false, foreign_key: true
      t.text :adresse, null: false
      t.string :email, null: false
      t.text :horaires, null: false
      t.string :nom, null: false
      t.string :telephone, null: false

      t.timestamps
    end
    add_index :contact_informations, [:groupe_instructeur_id, :nom], unique: true, name: 'index_contact_informations_on_gi_and_nom'
  end
end
