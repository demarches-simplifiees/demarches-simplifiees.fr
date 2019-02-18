class AddAdministrationColumnToLogDossierOperation < ActiveRecord::Migration[5.2]
  def change
    add_reference :dossier_operation_logs, :administration, foreign_key: true
  end
end
