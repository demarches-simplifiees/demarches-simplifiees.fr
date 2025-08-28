# frozen_string_literal: true

class AddForeignKeysToFollows < ActiveRecord::Migration[7.1]
  def change
    add_foreign_key :follows, :instructeurs, validate: false
    add_foreign_key :follows, :dossiers, validate: false
  end
end
