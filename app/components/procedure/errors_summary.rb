class Procedure::ErrorsSummary < ApplicationComponent
  ErrorDescriptor = Data.define(:anchor, :label, :error_message)

  def initialize(procedure:, validation_context:)
    @procedure = procedure
    @validation_context = validation_context
  end

  def title
    case @validation_context
    when :types_de_champ_private_editor
      "Les annotations privées contiennent des erreurs"
    when :types_de_champ_public_editor
      "Les champs formulaire contiennent des erreurs"
    when :publication
      if @procedure.publiee?
        "Des problèmes empêchent la publication des modifications"
      else
        "Des problèmes empêchent la publication de la démarche"
      end
    end
  end

  def invalid?
    @procedure.validate(@validation_context)
    @procedure.errors.present?
  end

  def errors
    @procedure.errors.map { to_error_descriptor(_1) }
  end

  def error_correction_page(error)
    case error.attribute
    when :ineligibilite_rules
      edit_admin_procedure_ineligibilite_rules_path(@procedure)
    when :draft_types_de_champ_public
      tdc = error.options[:type_de_champ]
      champs_admin_procedure_path(@procedure, anchor: dom_id(tdc.stable_self, :editor_error))
    when :draft_types_de_champ_private
      tdc = error.options[:type_de_champ]
      annotations_admin_procedure_path(@procedure, anchor: dom_id(tdc.stable_self, :editor_error))
    when :attestation_template
      edit_admin_procedure_attestation_template_path(@procedure)
    when :initiated_mail, :received_mail, :closed_mail, :refused_mail, :without_continuation_mail, :re_instructed_mail
      klass = "Mails::#{error.attribute.to_s.classify}".constantize
      edit_admin_procedure_mail_template_path(@procedure, klass.const_get(:SLUG))
    end
  end

  def to_error_descriptor(error)
    libelle = case error.attribute
    when :draft_types_de_champ_public, :draft_types_de_champ_private
      error.options[:type_de_champ].libelle.truncate(200)
    else
      error.base.class.human_attribute_name(error.attribute)
    end
    ErrorDescriptor.new(error_correction_page(error), libelle, error.message)
  end
end
