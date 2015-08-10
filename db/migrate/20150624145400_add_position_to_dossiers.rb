class AddPositionToDossiers < ActiveRecord::Migration
  def change
    add_column :dossiers, :position_lat, :string
    add_column :dossiers, :position_lon, :string
  end
end
