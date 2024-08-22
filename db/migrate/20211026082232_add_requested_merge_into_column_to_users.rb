# frozen_string_literal: true

class AddRequestedMergeIntoColumnToUsers < ActiveRecord::Migration[6.1]
  def change
    add_reference :users, :requested_merge_into, foreign_key: { to_table: :users }, null: true, index: true
  end
end
