# frozen_string_literal: true

class AddProcedureForeignKeyToBulkMessages < ActiveRecord::Migration[7.0]
  def change
    add_foreign_key :bulk_messages, :procedures, validate: false
  end
end
