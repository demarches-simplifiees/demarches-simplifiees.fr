class Admin::MailsController < AdminController
  before_action :retrieve_procedure

  def index

  end

  def update
    mail = current_administrateur.procedures.find(params[:procedure_id]).mail_templates.find(params[:id])
    mail.update_attributes(update_params)

    redirect_to admin_procedure_mails_path
  end

  private

  def update_params
    params.require(:mail_received).permit(:body, :object)
  end
end