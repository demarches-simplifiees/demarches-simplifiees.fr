# frozen_string_literal: true

class CreateZones < ActiveRecord::Migration[6.1]
  def change
    create_table :zones do |t|
      t.string :acronym, null: false, index: { unique: true }
      t.string :label

      t.timestamps
    end
  end
end
