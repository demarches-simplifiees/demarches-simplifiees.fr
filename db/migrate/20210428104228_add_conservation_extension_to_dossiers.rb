class AddConservationExtensionToDossiers < ActiveRecord::Migration[6.1]
  def change
    add_column :dossiers, :conservation_extension, :interval, default: 0.days
  end
end
