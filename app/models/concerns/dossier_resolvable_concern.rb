module DossierResolvableConcern
  extend ActiveSupport::Concern

  included do
    has_many :resolutions, class_name: 'DossierResolution', dependent: :destroy
  end
end
