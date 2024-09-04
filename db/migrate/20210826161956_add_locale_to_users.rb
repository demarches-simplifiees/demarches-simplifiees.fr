# frozen_string_literal: true

class AddLocaleToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :locale, :string
  end
end
