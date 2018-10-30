class AddGeoIdToGeoAreas < ActiveRecord::Migration[5.2]
  def change
    add_column :geo_areas, :geo_reference_id, :string
  end
end
