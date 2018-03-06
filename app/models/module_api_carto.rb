class ModuleAPICarto < ApplicationRecord
  belongs_to :procedure

  validates :use_api_carto, presence: true, allow_blank: true, allow_nil: false
  validates :quartiers_prioritaires, presence: true, allow_blank: true, allow_nil: false
  validates :cadastre, presence: true, allow_blank: true, allow_nil: false

  def classes
    modules =  ''

    modules += 'qp ' if quartiers_prioritaires?
    modules += 'cadastre ' if cadastre?

    modules
  end
end
