class MakeProceduresOrganisationNotNull < ActiveRecord::Migration[5.2]
  def change
    change_column_null :procedures, :organisation, false
  end
end
