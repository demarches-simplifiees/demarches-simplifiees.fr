# frozen_string_literal: true

class CreateDefaultZonesAdministrateurs < ActiveRecord::Migration[6.1]
  def change
    create_table :default_zones_administrateurs, id: false do |t|
      t.belongs_to :administrateur
      t.belongs_to :zone
    end
  end
end
