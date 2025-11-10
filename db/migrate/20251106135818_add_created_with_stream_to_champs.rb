# frozen_string_literal: true

class AddCreatedWithStreamToChamps < ActiveRecord::Migration[7.2]
  def change
    add_column :champs, :created_with_stream, :string
  end
end
