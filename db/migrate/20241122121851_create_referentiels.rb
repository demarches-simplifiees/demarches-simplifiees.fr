# frozen_string_literal: true

class CreateReferentiels < ActiveRecord::Migration[7.0]
  def change
    create_table :referentiels do |t|
      t.string :name, null: false
      t.timestamps
    end
  end
end
