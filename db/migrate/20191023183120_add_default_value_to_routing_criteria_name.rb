# frozen_string_literal: true

class AddDefaultValueToRoutingCriteriaName < ActiveRecord::Migration[5.2]
  def change
    change_column :procedures, :routing_criteria_name, :text, default: "Votre ville"
  end
end
