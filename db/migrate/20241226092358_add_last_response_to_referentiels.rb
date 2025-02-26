# frozen_string_literal: true

class AddLastResponseToReferentiels < ActiveRecord::Migration[7.0]
  def change
    add_column :referentiels, :last_response, :jsonb
  end
end
