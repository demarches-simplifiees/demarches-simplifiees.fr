# frozen_string_literal: true

class AddRoutingAlertToProcedures < ActiveRecord::Migration[7.0]
  def change
    add_column :procedures, :routing_alert, :boolean, default: false, null: false
  end
end
