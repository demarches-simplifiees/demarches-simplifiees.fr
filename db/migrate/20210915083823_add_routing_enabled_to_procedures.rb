# frozen_string_literal: true

class AddRoutingEnabledToProcedures < ActiveRecord::Migration[6.1]
  def change
    add_column :procedures, :routing_enabled, :boolean
  end
end
