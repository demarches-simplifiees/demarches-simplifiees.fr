module NewAdministrateur
  class MailTemplatesController < AdministrateurController
    include ActionView::Helpers::SanitizeHelper

    def preview
      mail_template = find_mail_template_by_slug(params[:id])
      dossier = Dossier.new(id: '1', procedure: procedure)

      @dossier = dossier
      @logo_url = procedure.logo.url
      @service = procedure.service
      @rendered_template = sanitize(mail_template.body)
      @actions = mail_template.actions_for_dossier(dossier)

      render(template: 'notification_mailer/send_notification', layout: 'mailers/notifications_layout')
    end

    private

    def procedure
      @procedure ||= current_administrateur.procedures.find(params[:procedure_id])
    end

    def mail_templates
      [
        procedure.initiated_mail_template,
        procedure.received_mail_template,
        procedure.closed_mail_template,
        procedure.refused_mail_template,
        procedure.without_continuation_mail_template
      ]
    end

    def find_mail_template_by_slug(slug)
      mail_templates.find { |template| template.class.const_get(:SLUG) == slug }
    end
  end
end
