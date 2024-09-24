# frozen_string_literal: true

class AddAPIEntrepriseTokenExpiresAtToProcedures < ActiveRecord::Migration[7.0]
  def change
    add_column :procedures, :api_entreprise_token_expires_at, :datetime, precision: nil
  end
end
