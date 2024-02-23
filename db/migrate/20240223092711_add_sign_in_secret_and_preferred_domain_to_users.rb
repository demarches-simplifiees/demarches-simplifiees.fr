# frozen_string_literal: true

class AddSignInSecretAndPreferredDomainToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :sign_in_secret, :string, default: nil
    add_column :users, :preferred_domain, :integer, default: nil
  end
end
