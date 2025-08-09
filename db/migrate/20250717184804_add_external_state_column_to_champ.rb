# frozen_string_literal: true

class AddExternalStateColumnToChamp < ActiveRecord::Migration[7.1]
  def change
    add_column :champs, :external_state, :string
  end
end
