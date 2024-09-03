# frozen_string_literal: true

class ChampsAddStableId < ActiveRecord::Migration[7.0]
  def change
    add_column :champs, :stable_id, :bigint
    add_column :champs, :stream, :string
  end
end
