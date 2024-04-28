# frozen_string_literal: true

class AddProcessExpiredToTraitements < ActiveRecord::Migration[6.1]
  def change
    add_column :traitements, :process_expired, :boolean
    add_index :traitements, :process_expired
  end
end
