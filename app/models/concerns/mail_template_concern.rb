module MailTemplateConcern
  extend ActiveSupport::Concern

  include Rails.application.routes.url_helpers
  include ActionView::Helpers::UrlHelper

  TAGS = {
    numero_dossier: {
      description: "Permet d'afficher le numéro de dossier de l'utilisateur.",
      templates: [
        "initiated_mail",
        "received_mail",
        "closed_mail",
        "refused_mail",
        "without_continuation_mail"
      ]
    },
    lien_dossier: {
      description: "Permet d'afficher un lien vers le dossier de l'utilisateur.",
      templates: [
        "initiated_mail",
        "received_mail",
        "closed_mail",
        "refused_mail",
        "without_continuation_mail"
      ]
    },
    libelle_procedure: {
      description: "Permet d'afficher le libellé de la procédure.",
      templates: [
        "initiated_mail",
        "received_mail",
        "closed_mail",
        "refused_mail",
        "without_continuation_mail"
      ]
    },
    date_de_decision: {
      description: "Permet d'afficher la date à laquelle la décision finale (acceptation, refus, classement sans suite) sur le dossier a été prise.",
      templates: [
        "closed_mail",
        "refused_mail",
        "without_continuation_mail"
      ]
    }
  }

  def self.tags_for_template(template)
    TAGS.select { |key, value| value[:templates].include?(template) }
  end

  def object_for_dossier(dossier)
    replace_tags(object, dossier)
  end

  def body_for_dossier(dossier)
    replace_tags(body, dossier)
  end

  def replace_tags(string, dossier)
    TAGS.inject(string) do |acc, tag|
      acc.gsub!("--#{tag.first}--", replace_tag(tag.first.to_sym, dossier)) || acc
    end
  end

  module ClassMethods
    def slug
      self.name.demodulize.underscore.parameterize
    end

    def default
      body = ActionController::Base.new.render_to_string(template: self.name.underscore)
      self.new(object: self.const_get(:DEFAULT_OBJECT), body: body)
    end
  end

  private

  def replace_tag(tag, dossier)
    case tag
    when :numero_dossier
      dossier.id.to_s
    when :lien_dossier
      link_to users_dossier_recapitulatif_url(dossier), users_dossier_recapitulatif_url(dossier), target: '_blank'
    when :libelle_procedure
      dossier.procedure.libelle
    when :date_de_decision
      dossier.processed_at.present? ? dossier.processed_at.strftime("%d/%m/%Y") : ""
    else
      '--BALISE_NON_RECONNUE--'
    end
  end
end
