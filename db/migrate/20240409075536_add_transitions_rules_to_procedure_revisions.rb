# frozen_string_literal: true

class AddTransitionsRulesToProcedureRevisions < ActiveRecord::Migration[7.0]
  def change
    add_column :procedure_revisions, :ineligibilite_rules, :jsonb
  end
end
