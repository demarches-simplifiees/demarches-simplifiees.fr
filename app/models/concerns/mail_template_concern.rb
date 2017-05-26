module MailTemplateConcern
  extend ActiveSupport::Concern

  include Rails.application.routes.url_helpers
  include ActionView::Helpers::UrlHelper

  TAGS = []
  TAGS << TAG_NUMERO_DOSSIER = {
    name:         "numero_dossier",
    description:  "Permet d'afficher le numéro de dossier de l'utilisateur."
  }
  TAGS << TAG_LIEN_DOSSIER = {
    name:         "lien_dossier",
    description:  "Permet d'afficher un lien vers le dossier de l'utilisateur."
  }
  TAGS << TAG_LIBELLE_PROCEDURE = {
    name:         "libelle_procedure",
    description:  "Permet d'afficher le libellé de la procédure."
  }
  TAGS << TAG_DATE_DE_DECISION = {
    name:         "date_de_decision",
    description:  "Permet d'afficher la date à laquelle la décision finale (acceptation, refus, classement sans suite) sur le dossier a été prise."
  }

  def object_for_dossier(dossier)
    replace_tags(object, dossier)
  end

  def body_for_dossier(dossier)
    replace_tags(body, dossier)
  end

  def replace_tags(string, dossier)
    TAGS.inject(string) do |acc, tag|
      acc.gsub!("--#{tag[:name]}--", replace_tag(tag, dossier)) || acc
    end
  end

  module ClassMethods
    def default
      body = ActionController::Base.new.render_to_string(template: self.const_get(:TEMPLATE_NAME))
      self.new(object: self.const_get(:DEFAULT_OBJECT), body: body)
    end
  end

  private

  def replace_tag(tag, dossier)
    case tag
    when TAG_NUMERO_DOSSIER
      dossier.id.to_s
    when TAG_LIEN_DOSSIER
      link_to users_dossier_recapitulatif_url(dossier), users_dossier_recapitulatif_url(dossier), target: '_blank'
    when TAG_LIBELLE_PROCEDURE
      dossier.procedure.libelle
    when TAG_DATE_DE_DECISION
      dossier.processed_at.present? ? dossier.processed_at.localtime.strftime("%d/%m/%Y") : ""
    else
      '--BALISE_NON_RECONNUE--'
    end
  end
end
