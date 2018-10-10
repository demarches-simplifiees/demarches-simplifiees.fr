class ModuleAPICarto < ApplicationRecord
  belongs_to :procedure

  validates :use_api_carto, presence: true, allow_blank: true, allow_nil: false
  validates :quartiers_prioritaires, presence: true, allow_blank: true, allow_nil: false
  validates :cadastre, presence: true, allow_blank: true, allow_nil: false
  validates :parcelles_agricoles, presence: true, allow_blank: true

  def classes
    modules = ''

    if quartiers_prioritaires?
      modules += 'qp '
    end

    if cadastre?
      modules += 'cadastre '
    end

    if parcelles_agricoles?
      modules += 'pa '
    end

    modules
  end
end
