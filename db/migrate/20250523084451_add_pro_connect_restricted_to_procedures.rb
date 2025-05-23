# frozen_string_literal: true

class AddProConnectRestrictedToProcedures < ActiveRecord::Migration[7.1]
  def change
    add_column :procedures, :pro_connect_restricted, :boolean, default: false, null: false
  end
end
