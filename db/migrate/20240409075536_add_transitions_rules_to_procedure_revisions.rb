class AddTransitionsRulesToProcedureRevisions < ActiveRecord::Migration[7.0]
  def change
    add_column :procedure_revisions, :transitions_rules, :jsonb
  end
end
