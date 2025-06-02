# frozen_string_literal: true

class AddInstructeursSelfManagementEnabledToProcedures < ActiveRecord::Migration[6.1]
  def change
    add_column :procedures, :instructeurs_self_management_enabled, :boolean
  end
end
