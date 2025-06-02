# frozen_string_literal: true

class AddDefaultToConservationExtension2 < ActiveRecord::Migration[6.1]
  def change
    change_column_default :dossiers, :conservation_extension, 0.days
  end
end
