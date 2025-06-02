# frozen_string_literal: true

class ChangeColumnDefaultProceduresInstructeursSelfManagementEnabled < ActiveRecord::Migration[7.0]
  def change
    safety_assured { change_column_default :procedures, :instructeurs_self_management_enabled, false }
  end
end
