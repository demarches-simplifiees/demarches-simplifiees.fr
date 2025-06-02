# frozen_string_literal: true

class AddExternalIdToChamps < ActiveRecord::Migration[6.0]
  def change
    add_column :champs, :external_id, :string
  end
end
