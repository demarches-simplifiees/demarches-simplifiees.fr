# frozen_string_literal: true

class RemoveRoutingCriteriaNameColumn < ActiveRecord::Migration[7.0]
  def change
    safety_assured do
      remove_column :procedures, :routing_criteria_name, :string, default: "Votre ville"
    end
  end
end
