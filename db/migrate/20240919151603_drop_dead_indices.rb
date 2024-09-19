# frozen_string_literal: true

class DropDeadIndices < ActiveRecord::Migration[7.0]
  def change
    remove_index :traitements, :process_expired
  end
end
