# frozen_string_literal: true

class CreateAPITokens < ActiveRecord::Migration[6.1]
  def change
    create_table :api_tokens, id: :uuid do |t|
      t.references :administrateur, null: false, foreign_key: true
      t.string :encrypted_token, null: false
      t.string :name, null: false
      t.integer :version, null: false, default: 3
      t.timestamps
    end
  end
end
