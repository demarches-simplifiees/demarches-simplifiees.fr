module DossierCorrectableConcern
  extend ActiveSupport::Concern

  included do
    A_CORRIGER = 'a_corriger'
    has_many :corrections, class_name: 'DossierCorrection', dependent: :destroy
    has_many :pending_corrections, -> { DossierCorrection.pending }, class_name: 'DossierCorrection', inverse_of: :dossier

    scope :with_pending_corrections, -> { joins(:corrections).where(corrections: { resolved_at: nil }) }

    def flag_as_pending_correction!(commentaire, kind = nil)
      return unless may_flag_as_pending_correction?

      kind ||= :correction

      corrections.create!(commentaire:, kind:)

      log_pending_correction_operation(commentaire, kind) if procedure.sva_svr_enabled?

      return if en_construction?

      repasser_en_construction_with_pending_correction!(instructeur: commentaire.instructeur)
    end

    def may_flag_as_pending_correction?
      return false if pending_corrections.exists?

      en_construction? || may_repasser_en_construction_with_pending_correction?
    end

    def pending_correction?
      # We don't want to show any alert if user is not allowed to modify the dossier
      return false unless en_construction?

      return pending_corrections.any? if pending_corrections.loaded?

      pending_corrections.exists?
    end

    def pending_correction
      pending_corrections.first
    end

    def resolve_pending_correction!
      pending_corrections.update!(resolved_at: Time.current)
      pending_corrections.reset
    end

    private

    def log_pending_correction_operation(commentaire, kind)
      operation = case kind.to_sym
      when :correction
        "demander_une_correction"
      when :incomplete
        "demander_a_completer"
      end

      log_dossier_operation(commentaire.instructeur, operation, commentaire)
    end
  end
end
