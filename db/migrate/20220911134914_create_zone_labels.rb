# frozen_string_literal: true

class CreateZoneLabels < ActiveRecord::Migration[6.1]
  def change
    create_table :zone_labels do |t|
      t.belongs_to :zone, null: false, foreign_key: true
      t.date :designated_on, null: false
      t.string :name, null: false

      t.timestamps
    end
  end
end
