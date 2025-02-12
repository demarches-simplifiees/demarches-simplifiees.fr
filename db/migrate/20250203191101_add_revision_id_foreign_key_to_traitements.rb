# frozen_string_literal: true

class AddRevisionIdForeignKeyToTraitements < ActiveRecord::Migration[7.0]
  def change
    add_foreign_key :traitements, :procedure_revisions, validate: false, column: :revision_id
  end
end
