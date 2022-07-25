class AddEtablissementInfosToServices < ActiveRecord::Migration[6.1]
  def change
    add_column :services, :etablissement_infos, :jsonb, default: {}
    add_column :services, :etablissement_lat, :decimal, precision: 10, scale: 6
    add_column :services, :etablissement_lng, :decimal, precision: 10, scale: 6
  end
end
