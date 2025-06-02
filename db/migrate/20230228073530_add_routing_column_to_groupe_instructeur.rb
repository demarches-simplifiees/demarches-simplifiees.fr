# frozen_string_literal: true

class AddRoutingColumnToGroupeInstructeur < ActiveRecord::Migration[6.1]
  def change
    add_column :groupe_instructeurs, :routing_rule, :jsonb
  end
end
