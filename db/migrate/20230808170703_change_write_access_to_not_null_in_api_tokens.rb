# frozen_string_literal: true

class ChangeWriteAccessToNotNullInAPITokens < ActiveRecord::Migration[6.1]
  def change
    add_check_constraint :api_tokens, "write_access IS NOT NULL", name: "api_tokens_write_access_null", validate: false
  end
end
