class Admin::MailsController < AdminController
  before_action :retrieve_procedure

  def index
    @mail_templates = @procedure.mail_templates
  end

  def edit
    @mail_template = @procedure.mail_templates.find(params[:id])
  end

  def update
    mail = @procedure.mail_templates.find(params[:id])
    mail.update_attributes(update_params)

    redirect_to admin_procedure_mails_path
  end

  private

  def update_params
    params.require(:mail_received).permit(:body, :object)
  end
end
