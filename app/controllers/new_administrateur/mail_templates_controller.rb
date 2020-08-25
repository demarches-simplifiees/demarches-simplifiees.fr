module NewAdministrateur
  class MailTemplatesController < AdministrateurController
    include ActionView::Helpers::SanitizeHelper

    def index
      @mail_templates = mail_templates
    end

    def edit
      @procedure = procedure
      @mail_template = find_mail_template_by_slug(params[:id])
    end

    def update
      @procedure = procedure
      mail_template = find_mail_template_by_slug(params[:id])

      if mail_template.update(update_params)
        flash.notice = "Email mis à jour"
      else
        flash.alert = mail_template.errors.full_messages
      end

      redirect_to edit_admin_procedure_mail_template_path(mail_template.procedure_id, params[:id])
    end

    def preview
      mail_template = find_mail_template_by_slug(params[:id])
      dossier = Dossier.new(id: '1', procedure: procedure)

      @dossier = dossier
      @logo_url = procedure.logo_url
      @service = procedure.service
      @rendered_template = sanitize(mail_template.rich_body.body.to_html)
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
      mail_template_id = params[:id]
      {
        procedure_id: params[:procedure_id],
        subject: params["mails_#{mail_template_id}"] ? params["mails_#{mail_template_id}"][:subject] : params["mails_#{mail_template_id}_mail"][:subject],
        body: params["mails_#{mail_template_id}"] ? params["mails_#{mail_template_id}"][:rich_body] : params["mails_#{mail_template_id}_mail"][:rich_body]
      }
    end
  end
end
