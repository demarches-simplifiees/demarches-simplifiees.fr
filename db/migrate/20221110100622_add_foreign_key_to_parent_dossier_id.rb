# frozen_string_literal: true

class AddForeignKeyToParentDossierId < ActiveRecord::Migration[6.1]
  def change
    add_foreign_key "dossiers", "dossiers", column: "parent_dossier_id", validate: false
  end
end
