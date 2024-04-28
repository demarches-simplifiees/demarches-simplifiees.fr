# frozen_string_literal: true

class AddReadOnlyAndProcedureIdsToAPITokens < ActiveRecord::Migration[6.1]
  def change
    add_column :api_tokens, :write_access, :boolean, default: true, null: false
    add_column :api_tokens, :allowed_procedure_ids, :bigint, array: true, null: true
  end
end
