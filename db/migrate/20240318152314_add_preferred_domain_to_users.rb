# frozen_string_literal: true

class AddPreferredDomainToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :preferred_domain, :integer, default: nil
  end
end
