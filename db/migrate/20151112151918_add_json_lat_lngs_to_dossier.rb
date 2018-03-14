class AddJsonLatLngsToDossier < ActiveRecord::Migration[5.2]
  def change
    add_column :dossiers, :json_latlngs, :text
  end
end
