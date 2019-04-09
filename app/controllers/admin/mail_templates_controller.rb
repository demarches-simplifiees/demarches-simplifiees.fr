class Admin::MailTemplatesController < AdminController
  before_action :retrieve_procedure

  def index
    @mail_templates = mail_templates
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
end
