# frozen_string_literal: true

class AddEnConstructionConservationExtensionToDossiers < ActiveRecord::Migration[5.2]
  def change
    add_column :dossiers, :en_construction_conservation_extension, :interval
  end
end
