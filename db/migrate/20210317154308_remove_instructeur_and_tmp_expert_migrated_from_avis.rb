class RemoveInstructeurAndTmpExpertMigratedFromAvis < ActiveRecord::Migration[6.0]
  def change
    remove_reference :avis, :instructeur, index: true
    remove_column :avis, :tmp_expert_migrated, :boolean
  end
end
