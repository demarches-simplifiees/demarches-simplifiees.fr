# frozen_string_literal: true

class RemoveUnusedColumns < ActiveRecord::Migration[5.2]
  def change
    remove_column :dossiers, :json_latlngs
    remove_column :services, :siret
  end
end
