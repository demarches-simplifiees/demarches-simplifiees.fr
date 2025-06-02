# frozen_string_literal: true

class AddConservationExtensionToDossiers < ActiveRecord::Migration[6.1]
  def change
    add_column :dossiers, :conservation_extension, :interval
  end
end
