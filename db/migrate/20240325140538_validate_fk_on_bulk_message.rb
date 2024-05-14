# frozen_string_literal: true

class ValidateFkOnBulkMessage < ActiveRecord::Migration[7.0]
  def change
    validate_foreign_key :bulk_messages, :procedures
  end
end
