# frozen_string_literal: true

class AddAuthenticationToReferentiels < ActiveRecord::Migration[7.1]
  def change
    add_column :referentiels, :authentication_method, :string
    add_column :referentiels, :authentication_data, :jsonb, default: {}
  end
end
