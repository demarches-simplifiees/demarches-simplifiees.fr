# frozen_string_literal: true

class CreateRdvConnections < ActiveRecord::Migration[7.0]
  def change
    create_table :rdv_connections do |t|
      t.string :access_token
      t.string :refresh_token
      t.datetime :expires_at
      t.references :instructeur, null: false, foreign_key: true, index: { unique: true }

      t.timestamps
    end
  end
end
