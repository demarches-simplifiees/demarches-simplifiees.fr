# frozen_string_literal: true

class AddRevisionIdToTraitements < ActiveRecord::Migration[7.0]
  def change
    add_column :traitements, :revision_id, :bigint, null: true
  end
end
