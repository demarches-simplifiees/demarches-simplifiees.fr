# frozen_string_literal: true

class AddDiscardedAtToChamps < ActiveRecord::Migration[7.0]
  def change
    add_column :champs, :discarded_at, :datetime
  end
end
