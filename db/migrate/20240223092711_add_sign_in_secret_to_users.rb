# frozen_string_literal: true

class AddSignInSecretToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :sign_in_secret, :string, default: nil
  end
end
