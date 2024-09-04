# frozen_string_literal: true

class AddDataToChamps < ActiveRecord::Migration[6.0]
  def change
    add_column :champs, :data, :jsonb
  end
end
