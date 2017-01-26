class Admin::MailTemplatesController < AdminController
  before_action :retrieve_procedure

  def index
    @mail_templates = @procedure.mail_templates
  end

  def edit
    @mail_template = @procedure.mail_templates.find(params[:id])
  end

  def update
    mail_template = @procedure.mail_templates.find(params[:id])
    mail_template.update_attributes(update_params)

    redirect_to admin_procedure_mail_templates_path
  end

  private

  def update_params
    params.require(:mail_template).permit(:body, :object)
  end
end
