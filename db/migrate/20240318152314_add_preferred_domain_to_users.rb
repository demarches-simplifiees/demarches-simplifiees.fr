# frozen_string_literal: true

class AddPreferredDomainToUsers < ActiveRecord::Migration[7.0]
  def change
    safety_assured do
      add_column :users, :preferred_domain, :integer, default: nil
    end
  end
end
