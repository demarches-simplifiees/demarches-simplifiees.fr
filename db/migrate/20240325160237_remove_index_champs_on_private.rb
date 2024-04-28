# frozen_string_literal: true

class RemoveIndexChampsOnPrivate < ActiveRecord::Migration[7.0]
  def change
    remove_index :champs, name: "index_champs_on_private"
  end
end
