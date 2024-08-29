# frozen_string_literal: true

class CreatePathRewrites < ActiveRecord::Migration[7.0]
  def change
    create_table :path_rewrites do |t|
      t.string :from, null: false
      t.string :to, null: false

      t.timestamps
    end
    add_index :path_rewrites, :from, unique: true
  end
end
