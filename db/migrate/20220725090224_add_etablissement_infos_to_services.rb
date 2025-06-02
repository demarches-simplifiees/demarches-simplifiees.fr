# frozen_string_literal: true

class AddEtablissementInfosToServices < ActiveRecord::Migration[6.1]
  def up
    add_column :services, :etablissement_infos, :jsonb
    add_column :services, :etablissement_lat, :decimal, precision: 10, scale: 6
    add_column :services, :etablissement_lng, :decimal, precision: 10, scale: 6
    change_column_default :services, :etablissement_infos, {}
  end

  def down
    remove_column :services, :etablissement_infos
    remove_column :services, :etablissement_lat
    remove_column :services, :etablissement_lng
  end
end
