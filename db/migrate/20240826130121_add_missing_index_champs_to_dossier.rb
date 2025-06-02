# frozen_string_literal: true

class AddMissingIndexChampsToDossier < ActiveRecord::Migration[7.0]
  def change
    add_foreign_key :champs, :dossiers, if_not_exists: true, validate: false
  end
end
