# frozen_string_literal: true

class AddDossiersCountToExports < ActiveRecord::Migration[7.0]
  def change
    add_column :exports, :dossiers_count, :integer, null: true, default: nil
  end
end
