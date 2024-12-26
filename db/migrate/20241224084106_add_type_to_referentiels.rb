# frozen_string_literal: true

class AddTypeToReferentiels < ActiveRecord::Migration[7.0]
  def change
    add_column :referentiels, :type, :string
  end
end
