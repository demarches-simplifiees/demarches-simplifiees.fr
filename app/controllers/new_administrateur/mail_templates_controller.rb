module NewAdministrateur
  class MailTemplatesController < AdministrateurController
    include ActionView::Helpers::SanitizeHelper
    
    def edit
      @procedure = procedure
      @mail_template = find_mail_template_by_slug(params[:id])
    end

    def update
      @procedure = procedure
      mail_template = find_mail_template_by_slug(params[:id])
      mail_template.update(update_params)
      redirect_to admin_procedure_mail_templates_path
    end

    def preview
      mail_template = find_mail_template_by_slug(params[:id])
      dossier = Dossier.new(id: '1', procedure: procedure)

      @dossier = dossier
      @logo_url = procedure.logo_url
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

    def update_params
      {
        procedure_id: params[:procedure_id],
        subject: params[:mail_template][:subject],
        body: params[:mail_template][:body]
      }
    end
  end
end
