class AddConditionsToProcedurePresentations < ActiveRecord::Migration[7.0]
  def change
    add_column :procedure_presentations, :conditions, :jsonb
  end
end
