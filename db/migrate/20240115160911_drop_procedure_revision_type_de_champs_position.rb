class DropProcedureRevisionTypeDeChampsPosition < ActiveRecord::Migration[7.0]
  def change
    change_column_null :procedure_revision_types_de_champ, :position, true, nil
  end
end
