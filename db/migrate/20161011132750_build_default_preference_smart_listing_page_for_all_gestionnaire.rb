class BuildDefaultPreferenceSmartListingPageForAllGestionnaire < ActiveRecord::Migration
  class Gestionnaire < ActiveRecord::Base
    has_one :preference_smart_listing_page, dependent: :destroy

    def build_default_preferences_smart_listing_page
      PreferenceSmartListingPage.create(page: 1, procedure: nil, gestionnaire: self, liste: 'a_traiter')
    end
  end

  class PreferenceSmartListingPage < ActiveRecord::Base
    belongs_to :gestionnaire
    belongs_to :procedure

    validates :page, presence: true, allow_blank: false, allow_nil: false
    validates :liste, presence: true, allow_blank: false, allow_nil: false
    validates :procedure, presence: true, allow_blank: true, allow_nil: true
    validates :gestionnaire, presence: true, allow_blank: false, allow_nil: false
  end

  def change
    Gestionnaire.all.each do |gestionnaire|
      gestionnaire.build_default_preferences_smart_listing_page if gestionnaire.preference_smart_listing_page.nil?
    end
  end
end
