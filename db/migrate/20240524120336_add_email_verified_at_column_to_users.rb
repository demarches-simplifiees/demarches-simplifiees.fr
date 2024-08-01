# frozen_string_literal: true

class AddEmailVerifiedAtColumnToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :email_verified_at, :datetime
  end
end
