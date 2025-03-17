# frozen_string_literal: true

class AddAPIParticulierTokenToProcedures < ActiveRecord::Migration[7.0]
  def change
    add_column :procedures, :api_particulier_token, :string
  end
end
