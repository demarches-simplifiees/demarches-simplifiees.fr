# frozen_string_literal: true

class AddForeignKeysToFollows < ActiveRecord::Migration[7.1]
  def change
    add_foreign_key :follows, :instructeurs, on_delete: :cascade, validate: false
    add_foreign_key :follows, :dossiers, on_delete: :cascade, validate: false
  end
end
