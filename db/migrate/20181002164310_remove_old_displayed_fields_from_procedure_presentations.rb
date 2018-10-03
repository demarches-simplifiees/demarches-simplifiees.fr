class RemoveOldDisplayedFieldsFromProcedurePresentations < ActiveRecord::Migration[5.2]
  def change
    remove_column :procedure_presentations, :old_displayed_fields
  end
end
