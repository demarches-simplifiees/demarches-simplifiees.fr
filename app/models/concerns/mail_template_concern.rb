module MailTemplateConcern
  extend ActiveSupport::Concern

  include Rails.application.routes.url_helpers
  include ActionView::Helpers::UrlHelper
  include TagsSubstitutionConcern

  def object_for_dossier(dossier)
    replace_tags(object, dossier)
  end

  def body_for_dossier(dossier)
    replace_tags(body, dossier)
  end

  def tags(is_dossier_termine: self.class.const_get(:IS_DOSSIER_TERMINE))
    super
  end

  module ClassMethods
    def default_for_procedure(procedure)
      body = ActionController::Base.new.render_to_string(template: self.const_get(:TEMPLATE_NAME))
      self.new(object: self.const_get(:DEFAULT_OBJECT), body: body, procedure: procedure)
    end
  end

  private

  def dossier_tags
    super + [{ libelle: 'lien dossier', description: '', lambda: -> (d) { users_dossier_recapitulatif_link(d) } }]
  end

  def users_dossier_recapitulatif_link(dossier)
    url = users_dossier_recapitulatif_url(dossier)
    link_to(url, url, target: '_blank')
  end
end
