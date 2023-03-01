class FixCleanMigrateTypeDeChampsEngagement < ActiveRecord::Migration[6.1]
  def change
    Champ.where(type: "Champs::EngagementChamp").in_batches do |batch|
      batch.update_all(type: 'Champs::CheckboxChamp')
    end
  end
end
