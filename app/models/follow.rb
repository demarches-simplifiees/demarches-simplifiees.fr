class Follow < ActiveRecord::Base
  belongs_to :gestionnaire
  belongs_to :dossier

  validates_uniqueness_of :gestionnaire_id, :scope => :dossier_id
end