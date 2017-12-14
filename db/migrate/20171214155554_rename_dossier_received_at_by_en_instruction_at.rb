class RenameDossierReceivedAtByEnInstructionAt < ActiveRecord::Migration[5.0]
  def change
    rename_column :dossiers, :received_at, :en_instruction_at
  end
end
