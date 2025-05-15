class AddDossierIneligbleMessageToProcedureRevisions < ActiveRecord::Migration[7.0]
  def change
    safety_assured do
      add_column :procedure_revisions, :ineligibilite_message, :text
    end
  end
end
