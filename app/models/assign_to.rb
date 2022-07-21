# == Schema Information
#
# Table name: assign_tos
#
#  id                                          :integer          not null, primary key
#  daily_email_notifications_enabled           :boolean          default(FALSE), not null
#  instant_email_dossier_notifications_enabled :boolean          default(FALSE), not null
#  instant_email_message_notifications_enabled :boolean          default(FALSE), not null
#  manager                                     :boolean          default(FALSE)
#  weekly_email_notifications_enabled          :boolean          default(TRUE), not null
#  created_at                                  :datetime
#  updated_at                                  :datetime
#  groupe_instructeur_id                       :bigint
#  instructeur_id                              :integer
#
class AssignTo < ApplicationRecord
  belongs_to :instructeur, optional: false
  belongs_to :groupe_instructeur, optional: false
  has_one :procedure_presentation, dependent: :destroy
  has_one :procedure, through: :groupe_instructeur

  scope :with_email_notifications, -> { where(daily_email_notifications_enabled: true) }

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
      Sentry.capture_message(
        "Destroying invalid ProcedurePresentation",
        extra: { procedure_presentation: procedure_presentation.as_json }
      )
      self.procedure_presentation = nil
      errors
    end
  end
end
