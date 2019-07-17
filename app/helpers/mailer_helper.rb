module MailerHelper
  def round_button(text, url)
    render 'shared/mailer_round_button', text: text, url: url
  end
end
