# frozen_string_literal: true

class AddIndexToCadastreStateOnGeoAreas < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    add_index :geo_areas, :cadastre_state, algorithm: :concurrently
  end
end
