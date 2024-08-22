# frozen_string_literal: true

class AddBrowserToTraitements < ActiveRecord::Migration[7.0]
  def change
    add_column :traitements, :browser_name, :string, null: true
    add_column :traitements, :browser_version, :integer, null: true
    add_column :traitements, :browser_supported, :boolean, null: true # rubocop:disable Rails/ThreeStateBooleanColumn
  end
end
