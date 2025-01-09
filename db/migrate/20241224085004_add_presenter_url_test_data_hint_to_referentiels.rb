# frozen_string_literal: true

class AddPresenterURLTestDataHintToReferentiels < ActiveRecord::Migration[7.0]
  def change
    add_column :referentiels, :url, :string
    add_column :referentiels, :test_data, :string
    add_column :referentiels, :hint, :string
    add_column :referentiels, :mode, :string
  end
end
