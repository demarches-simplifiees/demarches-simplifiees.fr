class AddPositionToDossiers < ActiveRecord::Migration[5.2]
  def change
    add_column :dossiers, :position_lat, :string
    add_column :dossiers, :position_lon, :string
  end
end
