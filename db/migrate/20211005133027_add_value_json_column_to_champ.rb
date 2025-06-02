# frozen_string_literal: true

class AddValueJSONColumnToChamp < ActiveRecord::Migration[6.1]
  def change
    add_column :champs, :value_json, :jsonb
  end
end
