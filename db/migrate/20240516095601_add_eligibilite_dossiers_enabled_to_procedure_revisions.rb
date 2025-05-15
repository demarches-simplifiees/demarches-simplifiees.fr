class AddEligibiliteDossiersEnabledToProcedureRevisions < ActiveRecord::Migration[7.0]
  def change
    safety_assured do
      add_column :procedure_revisions, :ineligibilite_enabled, :boolean, default: false, null: false
    end
  end
end
