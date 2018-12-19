class AddMissingTimestamps < ActiveRecord::Migration[5.2]
  def change
    add_timestamps :administrateurs_gestionnaires, null: true
    add_timestamps :geo_areas, null: true
  end
end
