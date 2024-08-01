# frozen_string_literal: true

class AddRebasedAtToChamps < ActiveRecord::Migration[6.1]
  def change
    add_column :champs, :rebased_at, :datetime
  end
end
