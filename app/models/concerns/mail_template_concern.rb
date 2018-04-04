module MailTemplateConcern
  extend ActiveSupport::Concern

  include TagsSubstitutionConcern

  def subject_for_dossier(dossier)
    replace_tags(subject, dossier)
  end

  def body_for_dossier(dossier)
    replace_tags(body, dossier)
  end

  module ClassMethods
    def default_for_procedure(procedure)
      template_name = default_template_name_for_procedure(procedure)
      body = ActionController::Base.new.render_to_string(template: template_name)
      new(subject: const_get(:DEFAULT_SUBJECT), body: body, procedure: procedure)
    end

    def default_template_name_for_procedure(procedure)
      const_get(:DEFAULT_TEMPLATE_NAME)
    end
  end

  def dossier_tags
    TagsSubstitutionConcern::DOSSIER_TAGS + TagsSubstitutionConcern::DOSSIER_TAGS_FOR_MAIL
  end
end
