module NewAdministrateur
  class MailTemplatesController < AdministrateurController
    include ActionView::Helpers::SanitizeHelper

    def preview
      @procedure = procedure
      @dossier = Dossier.new(id: 0)
      mail_template = find_mail_template_by_slug(params[:id])
      @logo_url = procedure.logo.url

      render(html: sanitize(mail_template.body), layout: 'mailers/notification')
    end

    private

    def procedure
      @procedure = current_administrateur.procedures.find(params[:procedure_id])
    end

    def mail_templates
      [
        @procedure.initiated_mail_template,
        @procedure.received_mail_template,
        @procedure.closed_mail_template,
        @procedure.refused_mail_template,
        @procedure.without_continuation_mail_template
      ]
    end

    def find_mail_template_by_slug(slug)
      mail_templates.find { |template| template.class.const_get(:SLUG) == slug }
    end
  end
end
