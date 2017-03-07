class Admin::MailTemplatesController < AdminController
  before_action :retrieve_procedure

  def index
    @mails = mails
  end

  def edit
    @mail_template = find_the_right_mail params[:id]
  end

  def update
    mail_template = find_the_right_mail params[:id]
    mail_template.update_attributes(update_params)
    redirect_to admin_procedure_mail_templates_path
  end

  private

  def mails
    %w(initiated received closed refused without_continuation)
      .map { |name| @procedure.send(name + "_mail") }
  end

  def find_the_right_mail type
    mails.find { |m| m.class.slug == type }
  end

  def update_params
    {
      procedure_id: params[:procedure_id],
      object: params[:mail_template][:object],
      body: params[:mail_template][:body],
    }
  end
end
