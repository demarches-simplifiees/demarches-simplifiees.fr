class AddSilenceVautDecisionToProcedure < ActiveRecord::Migration[5.2]
  def change
    add_column :procedures, :silence_vaut_decision_status, :string
    add_column :procedures, :silence_vaut_decision_delais, :integer
    add_column :procedures, :silence_vaut_decision_enabled, :boolean, default: false
  end
end
