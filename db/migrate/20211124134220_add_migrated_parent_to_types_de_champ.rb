# frozen_string_literal: true

class AddMigratedParentToTypesDeChamp < ActiveRecord::Migration[6.1]
  def change
    add_column :types_de_champ, :migrated_parent, :boolean
  end
end
