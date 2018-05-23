class AllowProcedureOrganismeToBeNull < ActiveRecord::Migration[5.2]
  def change
    change_column_null :procedures, :organisation, true
  end
end
