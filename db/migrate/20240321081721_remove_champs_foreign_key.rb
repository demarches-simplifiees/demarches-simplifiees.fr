# frozen_string_literal: true

class RemoveChampsForeignKey < ActiveRecord::Migration[7.0]
  def change
    remove_foreign_key :champs, column: :parent_id
    remove_index :champs, :parent_id
  end
end
