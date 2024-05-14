# frozen_string_literal: true

class AddTchapHsToZones < ActiveRecord::Migration[6.1]
  def change
    add_column :zones, :tchap_hs, :string, array: true, default: []
  end
end
