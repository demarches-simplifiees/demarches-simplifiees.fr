class Individual < ActiveRecord::Base
  belongs_to :dossier

  validates_uniqueness_of :dossier_id
end
