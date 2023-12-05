class Procedure::PublicationWarningComponent < ApplicationComponent
  def initialize(procedure:)
    @procedure = procedure
  end

  def title
    return "Des problèmes empêchent la publication des modifications" if @procedure.publiee?

    "Des problèmes empêchent la publication de la démarche"
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
    when :initiated_mail, :received_mail, :closed_mail, :refused_mail, :without_continuation_mail, :re_instructed_mail
      klass = "Mails::#{attribute.to_s.classify}".constantize
      edit_admin_procedure_mail_template_path(@procedure, klass.const_get(:SLUG))
    end
  end
end
