class AssignTo < ApplicationRecord
  belongs_to :procedure
  belongs_to :gestionnaire
  has_one :procedure_presentation, dependent: :destroy

  scope :with_email_notifications, -> { where(email_notifications_enabled: true) }

  def procedure_presentation_or_default_and_errors
    errors = reset_procedure_presentation_if_invalid
    [procedure_presentation || build_procedure_presentation, errors]
  end

  private

  def reset_procedure_presentation_if_invalid
    if procedure_presentation&.invalid?
      # This is a last defense against invalid `ProcedurePresentation`s persistently
      # hindering instructeurs. Whenever this gets triggered, it means that there is
      # a bug somewhere else that we need to fix.

      errors = procedure_presentation.errors
      Raven.capture_message(
        "Destroying invalid ProcedurePresentation",
        extra: { procedure_presentation: procedure_presentation.as_json }
      )
      self.procedure_presentation = nil
      errors
    end
  end
end
