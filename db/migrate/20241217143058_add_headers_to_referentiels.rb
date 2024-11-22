# frozen_string_literal: true

class AddHeadersToReferentiels < ActiveRecord::Migration[7.0]
  def change
    add_column :referentiels, :headers, :string, array: true, default: []
  end
end
