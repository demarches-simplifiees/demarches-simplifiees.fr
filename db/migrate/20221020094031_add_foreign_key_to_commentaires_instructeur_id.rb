# frozen_string_literal: true

class AddForeignKeyToCommentairesInstructeurId < ActiveRecord::Migration[6.1]
  def change
    add_foreign_key :commentaires, :instructeurs, validate: false
  end
end
