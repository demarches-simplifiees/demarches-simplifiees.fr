# frozen_string_literal: true

class AddProConnectRestrictionToProcedures < ActiveRecord::Migration[7.2]
  def change
    add_column :procedures, :pro_connect_restriction, :string, default: "none", null: false
  end
end
