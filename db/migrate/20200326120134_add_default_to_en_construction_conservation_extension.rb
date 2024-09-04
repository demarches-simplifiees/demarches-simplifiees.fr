# frozen_string_literal: true

class AddDefaultToEnConstructionConservationExtension < ActiveRecord::Migration[5.2]
  def change
    change_column :dossiers, :en_construction_conservation_extension, :interval, default: 0.days
  end
end
