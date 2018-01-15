class DropPreferenceSmartListingPages < ActiveRecord::Migration[5.0]
  def change
    drop_table :preference_smart_listing_pages
  end
end
