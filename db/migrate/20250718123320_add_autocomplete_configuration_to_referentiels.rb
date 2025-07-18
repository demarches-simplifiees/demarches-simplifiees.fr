# frozen_string_literal: true

class AddAutocompleteConfigurationToReferentiels < ActiveRecord::Migration[7.1]
  def change
    add_column :referentiels, :autocomplete_configuration, :jsonb, default: {}, null: false
  end
end
