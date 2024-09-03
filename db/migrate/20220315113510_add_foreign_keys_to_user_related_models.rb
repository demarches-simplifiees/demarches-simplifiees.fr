# frozen_string_literal: true

class AddForeignKeysToUserRelatedModels < ActiveRecord::Migration[6.1]
  def change
    # options = { type: :bigint, index: { unique: true }, foreign_key: true, null: true }
    # add_reference :administrateurs, :user, **options
    # add_reference :instructeurs,    :user, **options
    # add_reference :experts,         :user, **options
    add_column :administrateurs, :user_id, :bigint
    add_column :instructeurs, :user_id, :bigint
    add_column :experts, :user_id, :bigint
  end
end
