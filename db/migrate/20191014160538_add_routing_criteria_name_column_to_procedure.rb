# frozen_string_literal: true

class AddRoutingCriteriaNameColumnToProcedure < ActiveRecord::Migration[5.2]
  def change
    add_column :procedures, :routing_criteria_name, :text
  end
end
