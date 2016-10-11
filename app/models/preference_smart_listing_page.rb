class PreferenceSmartListingPage < ActiveRecord::Base
  belongs_to :gestionnaire
  belongs_to :procedure

  validates :page, presence: true, allow_blank: false, allow_nil: false
  validates :liste, presence: true, allow_blank: false, allow_nil: false
  validates :procedure, presence: true, allow_blank: true, allow_nil: true
  validates :gestionnaire, presence: true, allow_blank: false, allow_nil: false

  validates_uniqueness_of :gestionnaire_id
end
