class AddJsonLatLngsToDossier < ActiveRecord::Migration
  def change
    add_column :dossiers, :json_latlngs, :text
  end
end
