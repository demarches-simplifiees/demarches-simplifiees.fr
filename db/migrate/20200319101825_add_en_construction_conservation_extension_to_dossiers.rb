class AddEnConstructionConservationExtensionToDossiers < ActiveRecord::Migration[5.2]
  def change
    add_column :dossiers, :en_construction_conservation_extension, :interval, :default => 0.days
  end
end
