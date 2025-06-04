# frozen_string_literal: true

class ValidateForeignKeyChampsDossiers < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    validate_foreign_key :champs, :dossiers
  end
end
