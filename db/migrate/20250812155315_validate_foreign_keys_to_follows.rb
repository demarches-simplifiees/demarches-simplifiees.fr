# frozen_string_literal: true

class ValidateForeignKeysToFollows < ActiveRecord::Migration[7.1]
  def change
    validate_foreign_key :follows, :instructeurs
    validate_foreign_key :follows, :dossiers
  end
end
