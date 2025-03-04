# frozen_string_literal: true

class AddLocationTypeToRdvs < ActiveRecord::Migration[7.0]
  def change
    add_column :rdvs, :location_type, :string
  end
end
