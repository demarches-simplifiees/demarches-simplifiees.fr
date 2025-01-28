# frozen_string_literal: true

class AddPositionToLabels < ActiveRecord::Migration[7.0]
  def change
    add_column :labels, :position, :integer
  end
end
