# frozen_string_literal: true

class AddDailyFailuresToParkedAPIEntrepriseFetches < ActiveRecord::Migration[8.1]
  def change
    add_column :parked_api_entreprise_fetches, :daily_failures, :integer
  end
end
