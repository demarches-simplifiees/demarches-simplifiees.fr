# frozen_string_literal: true

class AddBypassEmailLoginTokenColumnToInstructeur < ActiveRecord::Migration[6.1]
  def change
    # This may take a while if running on Postgres < 11
    add_column :instructeurs, :bypass_email_login_token, :boolean, default: false, null: false
  end
end
