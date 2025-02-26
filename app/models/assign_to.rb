class AssignTo < ApplicationRecord
  belongs_to :instructeur, optional: false
  belongs_to :groupe_instructeur, optional: false
  has_one :procedure_presentation, dependent: :destroy
  has_one :procedure, through: :groupe_instructeur

  scope :with_email_notifications, -> { where(daily_email_notifications_enabled: true) }

  MIN_INACTIVE_DAYS = 40

  def procedure_presentation_or_default_and_errors
    errors = reset_procedure_presentation_if_invalid
    if self.procedure_presentation.nil?
      self.procedure_presentation = build_procedure_presentation
      self.procedure_presentation.save if procedure_presentation.valid? && !procedure_presentation.persisted?
    end
    [self.procedure_presentation, errors]
  end

  def self.cancel_notifications_for_inactive_instructeurs
    # given a procedure, notifications where instructeur has not followed a dossier since MIN_INACTIVE_DAYS
    AssignTo.joins(:procedure)
      .joins(instructeur: { all_follows: { dossier: :procedure } })
      .where('assign_tos.updated_at < ?', MIN_INACTIVE_DAYS.days.ago)
      .where(instant_email_dossier_notifications_enabled: true)
      .where("procedures.id = procedures_dossiers.id")
      .group("assign_tos.id")
      .having('max(greatest(follows.demande_seen_at, follows.messagerie_seen_at, follows.annotations_privees_seen_at, follows.avis_seen_at)) < ?', MIN_INACTIVE_DAYS.days.ago)
      .update_all(instant_email_dossier_notifications_enabled: false)

    # Given a procedure, notifications for a procedure where instructeur has never followed a dossier
    AssignTo.joins(:procedure)
      .joins(:instructeur)
      .left_outer_joins(instructeur: :all_follows)
      .where('assign_tos.updated_at < ?', MIN_INACTIVE_DAYS.days.ago)
      .where(instant_email_dossier_notifications_enabled: true)
      .where(follows: { id: nil })
      .group("assign_tos.id")
      .update_all(instant_email_dossier_notifications_enabled: false)
  end

  private

  def reset_procedure_presentation_if_invalid
    if procedure_presentation&.invalid?
      # This is a last defense against invalid `ProcedurePresentation`s persistently
      # hindering instructeurs. Whenever this gets triggered, it means that there is
      # a bug somewhere else that we need to fix.

      errors = procedure_presentation.errors
      Sentry.capture_message(
        "Destroying invalid ProcedurePresentation",
        extra: { procedure_presentation: procedure_presentation.as_json }
      )
      self.procedure_presentation = nil
      errors
    end
  end
end
