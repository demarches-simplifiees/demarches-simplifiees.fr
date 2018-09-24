class ChangeProcedurePresentationFieldsToJsonb < ActiveRecord::Migration[5.2]
  def change
    change_table(:procedure_presentations) do |t|
      t.rename :displayed_fields, :old_displayed_fields
      t.column :displayed_fields, :jsonb, null: false, default: [{ label: "Demandeur", table: "user", column: "email" }]
      t.change :sort, :jsonb, default: { table: "notifications", column: "notifications", order: "desc" }
      t.change :filters, :jsonb, default: { "a-suivre": [], suivis: [], traites: [], tous: [], archives: [] }
    end
  end
end
