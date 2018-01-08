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

  # TODO: remove legacy argument when removing legacy tags
  def tags(reject_legacy: true, is_dossier_termine: self.class.const_get(:IS_DOSSIER_TERMINE))
    super(is_dossier_termine: is_dossier_termine)
      .reject { |tag| reject_legacy && tag[:is_legacy] }
  end

  module ClassMethods
    def default_for_procedure(procedure)
      body = ActionController::Base.new.render_to_string(template: self.const_get(:TEMPLATE_NAME))
      self.new(object: self.const_get(:DEFAULT_OBJECT), body: body, procedure: procedure)
    end
  end

  private

  def dossier_tags
    super +
      [{ libelle: 'lien dossier', description: '', lambda: -> (d) { users_dossier_recapitulatif_link(d) } },
       # TODO: remove legacy tags
       { libelle: 'numero_dossier', description: '', target: :id, is_legacy: true },
       { libelle: 'lien_dossier', description: '', lambda: -> (d) { users_dossier_recapitulatif_link(d) }, is_legacy: true },
       { libelle: 'libelle_procedure', description: '', lambda: -> (d) { d.procedure.libelle }, is_legacy: true },
       { libelle: 'date_de_decision', description: '',
         lambda: -> (d) { d.processed_at.present? ? d.processed_at.localtime.strftime('%d/%m/%Y') : '' },
         dossier_termine_only: true, is_legacy: true }]
  end

  def users_dossier_recapitulatif_link(dossier)
    url = users_dossier_recapitulatif_url(dossier)
    link_to(url, url, target: '_blank')
  end
end
