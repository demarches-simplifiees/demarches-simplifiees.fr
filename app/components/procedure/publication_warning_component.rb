class Procedure::PublicationWarningComponent < ApplicationComponent
  def initialize(procedure:)
    @procedure = procedure
  end

  private

  def render?
    @procedure.validate(:publication)
    @procedure.errors.delete(:path)
    @procedure.errors.any?
  end

  def error_messages
    @procedure.errors
      .to_hash(full_messages: true)
      .map do |attribute, messages|
        [messages, error_correction_page(attribute)]
      end
  end

  def error_correction_page(attribute)
    case attribute
    when :draft_revision
      champs_admin_procedure_path(@procedure)
    when :attestation_template
      edit_admin_procedure_attestation_template_path(@procedure)
    when :initiated_mail, :received_mail, :closed_mail, :refused_mail, :without_continuation_mail
      admin_procedure_mail_templates_path(@procedure)
    end
  end
end
