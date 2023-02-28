module DossierResolvableConcern
  extend ActiveSupport::Concern

  included do
    has_many :resolutions, class_name: 'DossierResolution', dependent: :destroy

    def pending_resolution?
      # We don't want to show any alert if user is not allowed to modify the dossier
      return false unless en_construction?

      resolutions.pending.exists?
    end
  end
end
