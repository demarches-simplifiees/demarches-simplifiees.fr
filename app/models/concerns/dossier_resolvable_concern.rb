module DossierResolvableConcern
  extend ActiveSupport::Concern

  included do
    has_many :resolutions, class_name: 'DossierResolution', dependent: :destroy

    def flag_as_pending_correction!(commentaire)
      return unless may_flag_as_pending_correction?

      resolutions.create(commentaire:)

      return if en_construction?

      repasser_en_construction!(instructeur: commentaire.instructeur)
    end

    def may_flag_as_pending_correction?
      return false if resolutions.pending.exists?

      en_construction? || may_repasser_en_construction?
    end

    def pending_resolution?
      # We don't want to show any alert if user is not allowed to modify the dossier
      return false unless en_construction?

      resolutions.pending.exists?
    end
  end
end
