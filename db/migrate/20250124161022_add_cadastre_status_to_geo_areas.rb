# frozen_string_literal: true

class AddCadastreStatusToGeoAreas < ActiveRecord::Migration[7.0]
  def change
    add_column :geo_areas, :cadastre_state, :string
    add_column :geo_areas, :cadastre_error, :string
  end
end
