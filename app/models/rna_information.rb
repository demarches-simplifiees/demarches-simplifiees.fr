class RNAInformation < ActiveRecord::Base
  belongs_to :entreprise

  validates :association_id, presence: true, allow_blank: false, allow_nil: false
end
