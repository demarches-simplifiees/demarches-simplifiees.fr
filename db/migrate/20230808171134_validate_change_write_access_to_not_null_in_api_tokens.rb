# frozen_string_literal: true

class ValidateChangeWriteAccessToNotNullInAPITokens < ActiveRecord::Migration[6.1]
  def change
    validate_check_constraint :api_tokens, name: "api_tokens_write_access_null"
    safety_assured { change_column_null :api_tokens, :write_access, false }
    remove_check_constraint :api_tokens, name: "api_tokens_write_access_null"
  end
end
