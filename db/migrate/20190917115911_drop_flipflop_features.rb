# frozen_string_literal: true

class DropFlipflopFeatures < ActiveRecord::Migration[5.2]
  def change
    remove_column :administrateurs, :features
    remove_column :instructeurs, :features

    drop_table :flipflop_features
  end
end
