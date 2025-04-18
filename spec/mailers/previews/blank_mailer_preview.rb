# frozen_string_literal: true

class BlankMailerPreview < ActionMailer::Preview
  def send_template
    body = "<div><p>un paragraphe</p></div><p>un autre paragraphe et un <a href='ds.fr'>lien</a></p>"

    BlankMailer.send_template(
      to: User.first.email,
      subject: "un tres beau sujet",
      title: "Un super titre",
      body:
    )
  end
end
