class ChangeColumnDefaultProceduresInstructeursSelfManagementEnabled < ActiveRecord::Migration[7.0]
  def change
    change_column_default :procedures, :instructeurs_self_management_enabled, false
  end
end
