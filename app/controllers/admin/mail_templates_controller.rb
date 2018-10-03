class Admin::MailTemplatesController < AdminController
  before_action :retrieve_procedure

  def index
    @mail_templates = mail_templates
  end

  def edit
    @mail_template = find_mail_template_by_slug(params[:id])
  end

  def update
    mail_template = find_mail_template_by_slug(params[:id])
    mail_template.update(update_params)
    redirect_to admin_procedure_mail_templates_path
  end

  private

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

  def update_params
    {
      procedure_id: params[:procedure_id],
      subject: params[:mail_template][:subject],
      body: params[:mail_template][:body]
    }
  end
end
