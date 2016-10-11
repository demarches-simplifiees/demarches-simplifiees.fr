class CreatePreferenceSmartListingPage < ActiveRecord::Migration
  def change
    create_table :preference_smart_listing_pages, id: false do |t|
      t.string :liste
      t.integer :page
    end

    add_belongs_to :preference_smart_listing_pages, :procedure
    add_belongs_to :preference_smart_listing_pages, :gestionnaire

    add_index :preference_smart_listing_pages, :gestionnaire_id, unique: true
  end
end
